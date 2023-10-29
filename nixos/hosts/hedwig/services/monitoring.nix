{config, ...}: {
  services.prometheus = let
    promcfg = config.services.prometheus;
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
    ];

    exporters = {
      node = {
        enable = true;
        listenAddress = "[::1]";
        enabledCollectors = ["systemd"];
      };
    };
  };
}
