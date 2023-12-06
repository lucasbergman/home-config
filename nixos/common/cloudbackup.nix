{
  config,
  lib,
  pkgs,
  mypkgs,
  ...
}: {
  options = with lib; {
    slb.backups = {
      gcsPath = mkOption {
        type = types.str;
        description = "Google Cloud Storage path for backup storage";
        example = "/myhostname";
      };

      backupPaths = mkOption {
        type = with types; listOf str;
        description = "List of local paths to back up";
        example = ["/data" "/otherdata"];
      };

      passwordSecretID = mkOption {
        type = types.str;
        description = "Google Cloud Secrets Manager resource ID of Restic password secret";
        example = "projects/myproject/secrets/secret-name/versions/123";
      };

      exclude = mkOption {
        type = with types; listOf str;
        description = "List of patterns to exclude from backup";
        default = [];
      };
    };
  };

  config = let
    resticEnvFile =
      pkgs.writeText "restic.env"
      ''
        GOOGLE_APPLICATION_CREDENTIALS=/run/gcp-instance-creds.json
      '';
    cfg = config.slb.backups;
    myPasswordFile = "/run/restic-password";
  in {
    services.restic.backups = {
      gcsbackup = {
        timerConfig = {OnCalendar = "daily";};
        repository = "gs:bergmans-services-backup:${cfg.gcsPath}";
        paths = cfg.backupPaths;
        environmentFile = resticEnvFile.outPath;
        passwordFile = myPasswordFile;
        exclude = cfg.exclude;

        # Create the repo if it doesn't already exist. I guess this is
        # slightly dangerous, but doing without it is a hassle.
        initialize = true;

        # Limit to 2 Google Cloud Storage connections concurrently
        extraOptions = ["gs.connections=2"];
      };
    };

    systemd.services.restic-backup-password = {
      description = "populate the GCS backups password file";
      wantedBy = ["multi-user.target"];
      before = ["restic-backups-gcsbackup.service"];
      after = ["instance-key.service"];
      serviceConfig.Type = "oneshot";
      environment = {
        GOOGLE_APPLICATION_CREDENTIALS = "/run/gcp-instance-creds.json";
      };

      script = ''
        [[ -f ${myPasswordFile} ]] && exit 0
        install -m 0400 /dev/null ${myPasswordFile}
        "${mypkgs.cat-gcp-secret}"/bin/cat-gcp-secret \
          "${cfg.passwordSecretID}" > ${myPasswordFile}
      '';
    };
  };
}
