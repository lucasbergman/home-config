{
  config,
  lib,
  mypkgs,
  pkgs,
  ...
}:
{
  services.prometheus =
    let
      promcfg = config.services.prometheus;
      unpollercfg = config.slb.unpoller;
      hasscfg = config.services.home-assistant.config;
    in
    {
      enable = true;
      listenAddress = "10.6.0.2";
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
