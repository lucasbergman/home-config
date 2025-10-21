{
  config,
  lib,
  pkgs,
  mypkgs,
  ...
}:
{
  options.services.openarc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to enable the OpenARC service";
      default = false;
    };

    uid = lib.mkOption {
      type = lib.types.int;
      description = "User ID for the OpenARC daemon";
    };

    gid = lib.mkOption {
      type = with lib.types; nullOr int;
      description = "Group ID for the OpenARC daemon (null means match uid)";
      default = null;
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain for ARC signatures";
    };

    selector = lib.mkOption {
      type = lib.types.str;
      description = "Selector for ARC signatures";
    };

    socket = lib.mkOption {
      type = lib.types.str;
      default = "local:/run/openarc/openarc.socket";
      description = "Socket for OpenARC to listen on (e.g. local:/path/to/socket or inet:8891@localhost)";
    };

    mode = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "s"
          "v"
          "sv"
        ]
      );
      default = null;
      description = "Operating mode: s (sign), v (verify), or sv (sign and verify). If null, mode is inferred from InternalHosts.";
    };

    internalHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.1"
        "::1"
      ];
      description = "List of IP addresses or networks (CIDR) to treat as internal (trusted).";
    };

    runtimeDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory for OpenARC daemon's runtime state";
      default = "/run/openarc";
    };

    keyFile = lib.mkOption {
      type = lib.types.path;
      description = "Secret key file for ARC signatures";
    };

    milterUsers = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "List of users that should have permission to use the milter (e.g. postfix)";
    };
  };

  config =
    let
      cfg = config.services.openarc;
      gid = if cfg.gid == null then cfg.uid else cfg.gid;
    in
    lib.mkIf cfg.enable {
      users.groups.openarc = {
        inherit gid;
        members = cfg.milterUsers;
      };
      users.users.openarc = {
        uid = cfg.uid;
        group = "openarc";
        isSystemUser = true;
      };

      systemd.services.openarc-setup = {
        description = "Set up OpenARC state directory";
        before = [ "openarc.service" ];
        script = ''
          mkdir -p ${cfg.runtimeDir}
          mkdir -p ${cfg.runtimeDir}/tmp
          chmod 0750 ${cfg.runtimeDir}
          chown --recursive ${toString cfg.uid}:${toString gid} ${cfg.runtimeDir}
        '';
        serviceConfig.Type = "oneshot";
      };

      systemd.services.openarc =
        let
          internalHosts = pkgs.writeText "internal-hosts" (lib.concatStringsSep "\n" cfg.internalHosts);
          configFile = pkgs.writeText "openarc.conf" ''
            AuthservID ${cfg.domain}
            BaseDirectory ${cfg.runtimeDir}
            Domain ${cfg.domain}
            KeyFile ${cfg.keyFile}
            Selector ${cfg.selector}
            InternalHosts ${internalHosts}
            MilterDebug 1
            ${lib.optionalString (cfg.mode != null) "Mode ${cfg.mode}"}
            Socket ${cfg.socket}
            Syslog true
            TemporaryDirectory ${cfg.runtimeDir}/tmp
            UMask 007
          '';
        in
        {
          description = "OpenARC Milter";
          after = [
            "network.target"
            "openarc-setup.service"
          ];
          wantedBy = [ "multi-user.target" ];
          documentation = [
            "man:openarc(8)"
            "man:openarc.conf(5)"
            "man:openarc-keygen(1)"
          ];

          serviceConfig = {
            Type = "simple";
            User = "openarc";
            Group = "openarc";
            ExecStart = "${mypkgs.openarc}/bin/openarc -f -c ${configFile}";
            ExecReload = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
            Restart = "always";
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectHome = true;
          };
        };
    };
}
