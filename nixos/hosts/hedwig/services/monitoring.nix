{
  config,
  mypkgs,
  pkgs,
  ...
}: {
  imports = [../../../common/unpoller.nix];

  services.prometheus = let
    promcfg = config.services.prometheus;
    unpollercfg = config.slb.unpoller;
  in {
    enable = true;
    listenAddress = "[::1]";
    ruleFiles = [
      ../conf/prometheus/hedwig.yml
    ];

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
        job_name = "smart";
        static_configs = [{targets = ["[::1]:${toString promcfg.exporters.smartctl.port}"];}];
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
      {
        job_name = "unifi_jvm";
        static_configs = [{targets = ["[::1]:8444"];}];
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
      smartctl = {
        enable = true;
        listenAddress = "[::1]";
        devices = ["/dev/nvme0n1" "/dev/sda" "/dev/sdb" "/dev/sdc"];
      };
    };
  };

  users.groups.disk.members = ["smartctl-exporter"];

  slb.unpoller = {
    unifiUser = "unifipoller";
    unifiPasswordSecretID = "projects/bergmans-services/secrets/unpoller-password-hedwig/versions/1";
  };

  systemd.services."prometheus-htpasswd" = {
    description = "write Prometheus htpasswd file";
    wantedBy = ["multi-user.target"];
    before = ["nginx.service"];
    after = ["instance-key.service"];
    serviceConfig.Type = "oneshot";
    environment = {
      GOOGLE_APPLICATION_CREDENTIALS = "/run/gcp-instance-creds.json";
    };

    script = let
      htpasswdFile = "/run/prometheus.htpasswd";
      passwdSecret = "projects/bergmans-services/secrets/prometheus-password-hedwig/versions/1";
    in ''
      [[ -f ${htpasswdFile} ]] || install -m 0400 -o nginx -g nginx /dev/null ${htpasswdFile}
      chown nginx:nginx ${htpasswdFile}
      chmod 0400 ${htpasswdFile}
      ${mypkgs.cat-gcp-secret}/bin/cat-gcp-secret ${passwdSecret} | \
        ${pkgs.apacheHttpd}/bin/htpasswd -i ${htpasswdFile} metrics
    '';
  };

  services.nginx.virtualHosts."metrics.bergman.house" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      basicAuthFile = "/run/prometheus.htpasswd";
      proxyPass = "http://[::1]:${toString config.services.prometheus.port}";
      proxyWebsockets = true;
    };
  };
}
