{
  config,
  lib,
  pkgs,
  ...
}:
let
  promcfg = config.services.prometheus;
  alertmanagerEnvFile = "/run/alertmanager.env";
  dataDirectory = "/data/prometheus";
  grafanaDataDirectory = "/data/grafana";
  mkYAML = name: path: pkgs.writeText name (builtins.toJSON (import path));
in
{
  slb.security.secrets."pagerduty-key" = {
    outPath = alertmanagerEnvFile;
    template = pkgs.writeText "alertmanager.env" ''
      PAGERDUTY_SERVICE_KEY={{gcpSecret "projects/bergmans-services/secrets/pagerduty-key/versions/1"}}
    '';
    before = [ "alertmanager.service" ];
    group = "prometheus";
  };

  services.prometheus = {
    enable = true;
    listenAddress = "10.6.0.1";
    ruleFiles = [
      (mkYAML "prober_smartmouse.rules" ./monitoring_prober_smartmouse.nix)
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
        job_name = "home_dns";
        metrics_path = "/probe";
        scrape_interval = "5m";
        params = {
          module = [ "home_dns" ];
        };
        static_configs = [ { targets = [ "8.8.8.8:53" ]; } ];
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
        configFile = mkYAML "blackbox.yml" ./monitoring_blackbox.nix;
      };

      node = {
        enable = true;
        listenAddress = "[::1]";
        enabledCollectors = [ "systemd" ];
      };
    };

    alertmanager = {
      enable = true;
      listenAddress = "10.6.0.1";
      environmentFile = alertmanagerEnvFile;
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

  services.grafana = {
    enable = true;
    dataDir = grafanaDataDirectory;
    settings = {
      server = {
        http_addr = "[::1]";
        domain = "dash.bergmans.us";
        enforce_domain = true;
        root_url = "https://%(domain)s/";
      };
      smtp = {
        enabled = true;
        from_address = "grafana@bergmans.us";
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
