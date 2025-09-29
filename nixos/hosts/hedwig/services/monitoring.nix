{
  config,
  lib,
  mypkgs,
  pkgs,
  ...
}:
let
  myAddress = "10.6.0.2";
in
{
  services.prometheus =
    let
      promcfg = config.services.prometheus;
      unpollercfg = config.slb.unpoller;
      hasscfg = config.services.home-assistant.config;
    in
    {
      enable = true;
      retentionTime = "90d";
      listenAddress = myAddress;
      globalConfig = {
        scrape_timeout = "5s";
        evaluation_interval = "10s";
      };
      ruleFiles =
        let
          rulesAttrSet = import ./monitoring_rules.nix { inherit lib; };
        in
        [
          (builtins.toString (pkgs.writeText "rules.json" (builtins.toJSON rulesAttrSet)))
        ];

      scrapeConfigs = [
        {
          job_name = "node";
          scrape_interval = "10s";
          static_configs = [ { targets = [ "[::1]:${toString promcfg.exporters.node.port}" ]; } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.+):(.*)$";
              target_label = "instance";
              replacement = "hedwig:$2";
            }
          ];
        }
        {
          job_name = "smart";
          static_configs = [ { targets = [ "[::1]:${toString promcfg.exporters.smartctl.port}" ]; } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.+):(.*)$";
              target_label = "instance";
              replacement = "hedwig:$2";
            }
          ];
        }
        {
          job_name = "unifi";
          scrape_interval = "10s";
          static_configs = [ { targets = [ unpollercfg.prometheusListenAddr ]; } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.+):(.*)$";
              target_label = "instance";
              replacement = "hedwig:$2";
            }
          ];
        }
        {
          job_name = "unifi_jvm";
          static_configs = [ { targets = [ "[::1]:8444" ]; } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.+):(.*)$";
              target_label = "instance";
              replacement = "hedwig:$2";
            }
          ];
        }
        {
          job_name = "hass";
          static_configs = [ { targets = [ "[::1]:${toString hasscfg.http.server_port}" ]; } ];
          metrics_path = "/api/prometheus";
          relabel_configs = [
            {
              target_label = "instance";
              replacement = "hedwig:hass";
            }
          ];
        }
      ];

      alertmanagers = [
        {
          static_configs = [
            { targets = [ "${promcfg.alertmanager.listenAddress}:${toString promcfg.alertmanager.port}" ]; }
          ];
        }
      ];

      alertmanager = {
        enable = true;
        listenAddress = myAddress;
        webExternalUrl = "http://${myAddress}:${toString promcfg.alertmanager.port}";
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
            smtp_smarthost = "cheddar.internal.bergman.house:587";
            smtp_from = "alertmanager@bergmans.us";
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
          };
          receivers = [
            {
              name = "me-mail";
              email_configs = [
                {
                  to = "lucas+alerts@bergmans.us";
                  tls_config.insecure_skip_verify = true;
                }
              ];
            }
          ];
        };
      };

      exporters = {
        node = {
          enable = true;
          listenAddress = "[::1]";
          enabledCollectors = [ "systemd" ];
        };
        smartctl = {
          enable = true;
          listenAddress = "[::1]";
          devices = [
            "/dev/nvme0n1"
            "/dev/sda"
            "/dev/sdb"
            "/dev/sdc"
          ];
        };
      };
    };

  users.groups.disk.members = [ "smartctl-exporter" ];

  slb.unpoller = {
    enable = true;
    unifiUser = "unifipoller";
    unifiPasswordSecretID = "projects/bergmans-services/secrets/unpoller-password-hedwig/versions/1";
  };
}
