{
  config,
  lib,
  ...
}: let
  promcfg = config.services.prometheus;
  dataDirectory = "/data/prometheus";
in {
  services.prometheus = {
    enable = true;
    listenAddress = "[::1]";

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{targets = ["[::1]:${toString promcfg.exporters.node.port}"];}];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            regex = "(.+):(.*)$";
            target_label = "instance";
            replacement = "cheddar:$2";
          }
        ];
      }
      {
        job_name = "smartmouse";
        metrics_path = "/probe";
        params = {module = ["http_head_fast_2xx"];};
        static_configs = [{targets = ["https://smartmousetravel.com"];}];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
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
    ];

    exporters = {
      blackbox = {
        enable = true;
        listenAddress = "[::1]";
        configFile = ./../conf/prometheus-blackbox.yml;
      };

      node = {
        enable = true;
        listenAddress = "[::1]";
        enabledCollectors = ["systemd"];
      };
    };
  };
}
