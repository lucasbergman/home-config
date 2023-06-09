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
      };
    };

    systemd.services.restic-backups-gcsbackup.preStart = ''
      [[ -f ${myPasswordFile} ]] && exit 0
      install -m 0400 /dev/null ${myPasswordFile}
      env GOOGLE_APPLICATION_CREDENTIALS=/run/gcp-instance-creds.json \
        "${mypkgs.cat-gcp-secret}"/bin/cat-gcp-secret \
        "${cfg.passwordSecretID}" > ${myPasswordFile}
    '';
  };
}
