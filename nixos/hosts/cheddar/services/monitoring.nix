{
  config,
  lib,
  pkgs,
  ...
}:
let
  promcfg = config.services.prometheus;
  dataDirectory = "/data/prometheus";
  grafanaDataDirectory = "/data/grafana";
  textfileDir = "/run/prometheus-node-exporter";
  mkYAML =
    name: path: attrs:
    pkgs.writeText name (builtins.toJSON (import path attrs));
  promNftablesBlocked = pkgs.writers.writePython3 "prom-nftables-blocked" {
    # Ignore flake8 rules that conflict with Black formatting (enforced by treefmt)
    flakeIgnore = [
      "E203"
      "E501"
    ];
  } (builtins.readFile ./prom-nftables-blocked.py);
in
{
  slb.security.secrets."pagerduty-key" = {
    restartUnits = [ "alertmanager.service" ];
    secretPath = "projects/bergmans-services/secrets/pagerduty-key/versions/1";
  };

  services.prometheus = {
    enable = true;
    listenAddress = "10.7.1.4";
    ruleFiles = [
      (mkYAML "firewall.rules" ./monitoring_firewall.nix { })
      (mkYAML "mail.rules" ./monitoring_mail.nix { inherit lib; })
      (mkYAML "prober_smartmouse.rules" ./monitoring_prober_smartmouse.nix { })
    ];

    alertmanagers = [
      {
        static_configs = [
          { targets = [ "${promcfg.alertmanager.listenAddress}:${toString promcfg.alertmanager.port}" ]; }
        ];
      }
    ];

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [ { targets = [ "[::1]:${toString promcfg.exporters.node.port}" ]; } ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            regex = "(.+):(.*)$";
            target_label = "instance";
            replacement = "cheddar:$2";
          }
        ];
      }
      {
        job_name = "postfix";
        static_configs = [ { targets = [ "[::1]:${toString promcfg.exporters.postfix.port}" ]; } ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            regex = "(.+):(.*)$";
            target_label = "instance";
            replacement = "cheddar:$2";
          }
        ];
      }
      {
        job_name = "smartmouse";
        metrics_path = "/probe";
        params = {
          module = [ "http_head_fast_2xx" ];
        };
        static_configs = [ { targets = [ "https://smartmousetravel.com" ]; } ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "[::1]:${toString promcfg.exporters.blackbox.port}";
          }
          {
            target_label = "instance";
            replacement = "cheddar:${toString promcfg.exporters.blackbox.port}";
          }
        ];
      }
      {
        job_name = "synapse";
        metrics_path = "/_synapse/metrics";
        static_configs = [ { targets = [ "[::1]:8009" ]; } ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            regex = "(.+):(.*)$";
            target_label = "instance";
            replacement = "cheddar:$2";
          }
        ];
      }
    ];

    exporters = {
      blackbox = {
        enable = true;
        listenAddress = "[::1]";
        configFile = mkYAML "blackbox.yml" ./monitoring_blackbox.nix { };
      };

      node = {
        enable = true;
        listenAddress = "[::1]";
        enabledCollectors = [
          "systemd"
          "textfile"
        ];
        extraFlags = [
          "--collector.textfile.directory=${textfileDir}"
        ];
      };

      postfix = {
        enable = true;
        listenAddress = "[::1]";
      };
    };

    alertmanager = {
      enable = true;
      listenAddress = "10.7.1.4";
      logLevel = "debug";

      extraFlags = [
        # Turn off HA/cluster mode. That's a good idea in single-server setups
        # anyway - might as well reduce one's attack surface - but I found out
        # that this wasn't the default in a stupid way. On a Linode VM with no
        # RFC 1918 private interface (only loopback and public), alertmanager
        # dies at startup saying "Failed to get final advertise address: No
        # private IP address found".
        "--cluster.listen-address=''"
      ];

      configuration = {
        global = {
          smtp_smarthost = "localhost:25";
          smtp_from = "alertmanager@bergmans.us";
          smtp_require_tls = false;
        };
        route = {
          group_by = [
            "alertname"
            "cluster"
            "service"
          ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
          receiver = "me-mail"; # default receiver
          routes = [
            {
              match = {
                severity = "page";
              };
              receiver = "pagerduty";
            }
          ];
        };
        receivers = [
          {
            name = "me-mail";
            email_configs = [ { to = "lucas+alerts@bergmans.us"; } ];
          }
          {
            name = "pagerduty";
            pagerduty_configs = [ { service_key = "$PAGERDUTY_SERVICE_KEY"; } ];
          }
        ];
      };
    };
  };

  systemd.services.alertmanager.preStart = lib.mkBefore ''
    export PAGERDUTY_SERVICE_KEY="$(cat "$CREDENTIALS_DIRECTORY/pagerduty-key")"
  '';

  networking.firewall.extraInputRules = lib.mkAfter ''
    counter drop comment "nixos-fw-input"
  '';

  systemd.services.prom-nftables-blocked = {
    description = "Export nftables drop counters for Prometheus";
    after = [ "nftables.service" ];
    wants = [ "nftables.service" ];
    path = [ pkgs.nftables ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${promNftablesBlocked} ${textfileDir}/nftables_blocked.prom";
      RuntimeDirectory = "prometheus-node-exporter";
      RuntimeDirectoryPreserve = "yes";
    };
  };

  systemd.timers.prom-nftables-blocked = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15s";
      OnUnitActiveSec = "1m";
      AccuracySec = "5s";
    };
  };

  services.grafana = {
    enable = true;
    dataDir = grafanaDataDirectory;
    settings = {
      server = {
        http_addr = "::1";
        domain = "dash.bergmans.us";
        enforce_domain = true;
        root_url = "https://%(domain)s/";
      };
      smtp = {
        enabled = true;
        from_address = "grafana@bergmans.us";
      };
      security = {
        secret_key = "SW2YcwTIb9zpOOhoPsMm";
      };
    };
  };

  services.nginx.virtualHosts.${config.services.grafana.settings.server.domain} = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
    };
  };
}
