{
  config,
  lib,
  mypkgs,
  ...
}: let
  promcfg = config.services.prometheus;
  alertmanagerEnvFile = "/run/alertmanager.env";
  dataDirectory = "/data/prometheus";
in {
  systemd.services."pagerduty-key" = {
    description = "decrypt PagerDuty key";
    wantedBy = ["multi-user.target"];
    before = ["alertmanager.service"];
    after = ["instance-key.service"];
    serviceConfig.Type = "oneshot";
    environment = {
      GOOGLE_APPLICATION_CREDENTIALS = "/run/gcp-instance-creds.json";
    };

    script = ''
      if [[ ! -f ${alertmanagerEnvFile} ]]; then
        install -m 0640 -g prometheus /dev/null ${alertmanagerEnvFile}
        ${mypkgs.gcp-secret-subst}/bin/gcp-secret-subst \
          ${./../conf/prometheus-alertmanager.env}      \
          > ${alertmanagerEnvFile}
      fi
    '';
  };

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

    alertmanager = {
      enable = true;
      listenAddress = "[::1]";
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
          group_by = ["alertname" "cluster" "service"];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
          receiver = "me-mail"; # default receiver
          routes = [
            {
              match = {severity = "page";};
              receiver = "pagerduty";
            }
          ];
        };
        receivers = [
          {
            name = "me-mail";
            email_configs = [{to = "lucas+alerts@bergmans.us";}];
          }
          {
            name = "pagerduty";
            pagerduty_configs = [{service_key = "$PAGERDUTY_SERVICE_KEY";}];
          }
        ];
      };
    };
  };
}
