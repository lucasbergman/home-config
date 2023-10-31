{config, ...}: {
  imports = [../../../common/unpoller.nix];

  services.prometheus = let
    promcfg = config.services.prometheus;
    unpollercfg = config.slb.unpoller;
  in {
    enable = true;
    listenAddress = "[::1]";
    ruleFiles = [];

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{targets = ["[::1]:${toString promcfg.exporters.node.port}"];}];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            regex = "(.+):(.*)$";
            target_label = "instance";
            replacement = "hedwig:$2";
          }
        ];
      }
      {
        job_name = "unifi";
        static_configs = [{targets = [unpollercfg.prometheusListenAddr];}];
        relabel_configs = [
          {
            source_labels = ["__address__"];
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
        enabledCollectors = ["systemd"];
      };
    };
  };

  slb.unpoller = {
    unifiUser = "unifipoller";
    unifiPasswordSecretID = "projects/bergmans-services/secrets/unpoller-password-hedwig/versions/1";
  };
}
