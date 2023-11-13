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
    };
  };

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
      if [[ ! -f ${htpasswdFile} ]]; then
        install -m 0400 -o nginx -g nginx /dev/null ${htpasswdFile}
        ${mypkgs.cat-gcp-secret}/bin/cat-gcp-secret ${passwdSecret} | \
          ${pkgs.apacheHttpd}/bin/htpasswd -ic ${htpasswdFile} metrics
      fi
    '';
  };

  # TODO: After hedwig is exposed to the Internet, we can remove this (and the
  # acme/nginx group hack) and just use enableACME in the nginx module
  security.acme.certs."metrics.bergman.house" = {};

  services.nginx.virtualHosts."metrics.bergman.house" = {
    forceSSL = true;
    useACMEHost = "metrics.bergman.house";
    locations."/" = {
      basicAuthFile = "/run/prometheus.htpasswd";
      proxyPass = "http://[::1]:${toString config.services.prometheus.port}";
      proxyWebsockets = true;
    };
  };
}
