{
  config,
  options,
  lib,
  pkgs,
  utils,
  ...
}:
with lib; let
  cfg = config.slb.unifi;
  stateDir = "/var/lib/unifi";
  cmd = ''
    @${cfg.jrePackage}/bin/java java \
        ${optionalString (versionAtLeast (getVersion cfg.jrePackage) "16")
      ("--add-opens java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED "
        + "--add-opens java.base/sun.security.util=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED "
        + "--add-opens java.rmi/sun.rmi.transport=ALL-UNNAMED")} \
        ${optionalString (cfg.initialJavaHeapSize != null) "-Xms${(toString cfg.initialJavaHeapSize)}m"} \
        ${optionalString (cfg.maximumJavaHeapSize != null) "-Xmx${(toString cfg.maximumJavaHeapSize)}m"} \
        -jar ${stateDir}/lib/ace.jar
  '';
in {
  # TODO: Remove this once changes land in the NixOS release
  options = {
    slb.unifi.enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether or not to enable the unifi controller service.
      '';
    };

    slb.unifi.jrePackage = mkOption {
      type = types.package;
      default =
        if (versionAtLeast (getVersion cfg.unifiPackage) "7.5")
        then pkgs.jdk17_headless
        else if (versionAtLeast (getVersion cfg.unifiPackage) "7.3")
        then pkgs.jdk11
        else pkgs.jre8;
      defaultText = literalExpression ''if (lib.versionAtLeast (lib.getVersion cfg.unifiPackage) "7.5") then pkgs.jdk17_headless else if (lib.versionAtLeast (lib.getVersion cfg.unifiPackage) "7.3" then pkgs.jdk11 else pkgs.jre8'';
      description = mdDoc ''
        The JRE package to use. Check the release notes to ensure it is supported.
      '';
    };

    slb.unifi.unifiPackage = mkOption {
      type = types.package;
      default = pkgs.unifi5;
      defaultText = literalExpression "pkgs.unifi5";
      description = mdDoc ''
        The unifi package to use.
      '';
    };

    slb.unifi.mongodbPackage = mkOption {
      type = types.package;
      default = pkgs.mongodb-4_4;
      defaultText = literalExpression "pkgs.mongodb";
      description = mdDoc ''
        The mongodb package to use. Please note: unifi7 officially only supports mongodb up until 3.6 but works with 4.4.
      '';
    };

    slb.unifi.initialJavaHeapSize = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 1024;
      description = mdDoc ''
        Set the initial heap size for the JVM in MB. If this option isn't set, the
        JVM will decide this value at runtime.
      '';
    };

    slb.unifi.maximumJavaHeapSize = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 4096;
      description = mdDoc ''
        Set the maximum heap size for the JVM in MB. If this option isn't set, the
        JVM will decide this value at runtime.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.unifi = {
      isSystemUser = true;
      group = "unifi";
      description = "UniFi controller daemon user";
      home = "${stateDir}";
    };
    users.groups.unifi = {};

    systemd.services.unifi = {
      description = "UniFi controller daemon";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      # This a HACK to fix missing dependencies of dynamic libs extracted from jars
      environment.LD_LIBRARY_PATH = with pkgs.stdenv; "${cc.cc.lib}/lib";
      # Make sure package upgrades trigger a service restart
      restartTriggers = [cfg.unifiPackage cfg.mongodbPackage];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${(removeSuffix "\n" cmd)} start";
        ExecStop = "${(removeSuffix "\n" cmd)} stop";
        Restart = "on-failure";
        TimeoutSec = "5min";
        User = "unifi";
        UMask = "0077";
        WorkingDirectory = "${stateDir}";
        # the stop command exits while the main process is still running, and unifi
        # wants to manage its own child processes. this means we have to set KillSignal
        # to something the main process ignores, otherwise every stop will have unifi.service
        # fail with SIGTERM status.
        KillSignal = "SIGCONT";

        # Hardening
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        # ProtectClock= adds DeviceAllow=char-rtc r
        DeviceAllow = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = ["@system-service"];

        StateDirectory = "unifi";
        RuntimeDirectory = "unifi";
        LogsDirectory = "unifi";
        CacheDirectory = "unifi";

        TemporaryFileSystem = [
          # required as we want to create bind mounts below
          "${stateDir}/webapps:rw"
        ];

        # We must create the binary directories as bind mounts instead of symlinks
        # This is because the controller resolves all symlinks to absolute paths
        # to be used as the working directory.
        BindPaths = [
          "/var/log/unifi:${stateDir}/logs"
          "/run/unifi:${stateDir}/run"
          "${cfg.unifiPackage}/dl:${stateDir}/dl"
          "${cfg.unifiPackage}/lib:${stateDir}/lib"
          "${cfg.mongodbPackage}/bin:${stateDir}/bin"
          "${cfg.unifiPackage}/webapps/ROOT:${stateDir}/webapps/ROOT"
        ];

        # Needs network access
        PrivateNetwork = false;
        # Cannot be true due to OpenJDK
        MemoryDenyWriteExecute = false;
      };
    };
  };
}
