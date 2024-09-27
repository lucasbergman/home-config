{
  config,
  lib,
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
    unpollerPassFile = "/run/unpoller-password";
  in {
    users.groups.unifi-poller = {};
    users.users.unifi-poller = {
      description = "unifi-poller Service User";
      group = "unifi-poller";
      isSystemUser = true;
    };

    slb.security.secrets.unifi-poller-password = {
      before = ["unifi-poller.service"];
      outPath = unpollerPassFile;
      group = "unifi-poller";
      secretPath = cfg.unifiPasswordSecretID;
    };

    systemd.services.unifi-poller = let
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
}
