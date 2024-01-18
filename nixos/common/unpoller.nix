{
  config,
  lib,
  mypkgs,
  pkgs,
  ...
}: {
  options.slb.unpoller = {
    unifiUser = lib.mkOption {
      type = lib.types.str;
      description = "The UniFi user name to use for polling";
    };

    unifiPasswordSecretID = lib.mkOption {
      type = lib.types.str;
      description = "GCP secret ID with the UniFi password for polling";
    };

    prometheusListenAddr = lib.mkOption {
      type = lib.types.str;
      description = "Address/port to export Prometheus-compatible metrics";
      default = "[::1]:9130";
    };
  };

  config = let
    cfg = config.slb.unpoller;
  in {
    users.groups.unifi-poller = {};
    users.users.unifi-poller = {
      description = "unifi-poller Service User";
      group = "unifi-poller";
      isSystemUser = true;
    };

    systemd.services = let
      unpollerPassFile = "/run/unpoller-password";
    in {
      unifi-poller-password = {
        description = "populate the UniFi poller password file";
        wantedBy = ["multi-user.target"];
        before = ["unifi-poller.service"];
        after = ["instance-key.service"];
        serviceConfig.Type = "oneshot";
        environment = {
          GOOGLE_APPLICATION_CREDENTIALS = "/run/gcp-instance-creds.json";
        };

        script = ''
          [[ -f ${unpollerPassFile} ]] && exit 0
          install -m 0440 -g unifi-poller /dev/null ${unpollerPassFile}
          env GOOGLE_APPLICATION_CREDENTIALS=/run/gcp-instance-creds.json \
            "${mypkgs.cat-gcp-secret}"/bin/cat-gcp-secret \
            "${cfg.unifiPasswordSecretID}" > ${unpollerPassFile}
        '';
      };

      unifi-poller = let
        configFile = pkgs.writeText "unpoller.json" (builtins.toJSON {
          prometheus.http_listen = cfg.prometheusListenAddr;
          influxdb.disable = true;
          unifi = {
            dynamic = false;
            controllers = [
              {
                user = cfg.unifiUser;
                pass = "file://${unpollerPassFile}";
                url = "https://127.0.0.1:8443/";
                verify_ssl = false;
              }
            ];
          };
        });
      in {
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = {
          ExecStart = "${pkgs.unpoller}/bin/unpoller --config ${configFile}";
          Restart = "always";
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "full";
          DevicePolicy = "closed";
          NoNewPrivileges = true;
          User = "unifi-poller";
          WorkingDirectory = "/tmp";
        };
      };
    };
  };
}
