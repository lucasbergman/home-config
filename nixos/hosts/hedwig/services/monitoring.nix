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
    in
    {
      enable = true;
      listenAddress = "10.6.0.2";
      ruleFiles = [
        (builtins.toString (pkgs.writeText "rules.json" (builtins.toJSON (import ./monitoring_rules.nix))))
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
