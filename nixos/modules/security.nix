{
  config,
  lib,
  pkgs,
  mypkgs,
  ...
}:
{
  options = {
    slb.security = {
      unsafeUnderConstruction = lib.mkOption {
        type = lib.types.bool;
        description = "Leave safety belts unbuckled when a machine is first getting set up";
        default = false;
      };

      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Whether to enable GCP security services (and ACME certs)";
        default = true;
      };

      acmeHostName = lib.mkOption {
        type = lib.types.str;
        description = "Host name (FQDN) for this host's main ACME certificate";
        default =
          let
            n = config.networking;
          in
          "${n.hostName}.${n.domain}";
      };

      secrets = lib.mkOption {
        default = { };
        type =
          with lib.types;
          attrsOf (submodule {
            options = {
              outPath = lib.mkOption {
                description = "Output path for secret material. If null, the secret is written to /run/credstore/<name> for use with systemd credentials.";
                type = nullOr path;
                default = null;
              };
              secretPath = lib.mkOption {
                description = "Path to secret to write; cannot be set with template";
                type = nullOr str;
                default = null;
              };
              template = lib.mkOption {
                description = "Input template that is processed to substitute secret material; cannot be set with secretPath";
                type = nullOr path;
                default = null;
              };
              after = lib.mkOption {
                description = "List of systemd units that secret writing should wait for";
                type = listOf str;
                default = [ ];
              };
              before = lib.mkOption {
                description = "List of systemd units that should be delayed until after secrets are written";
                type = listOf str;
                default = [ ];
              };
              owner = lib.mkOption {
                description = "User that will own the output file (only used when outPath != null)";
                type = str;
                default = "root";
              };
              group = lib.mkOption {
                description = "Group that will own the output file; if null, output file is not group-readable (only used when outPath != null)";
                type = nullOr str;
                default = null;
              };
              restartUnits = lib.mkOption {
                description = "List of systemd units that should restart when this secret changes";
                type = listOf str;
                default = [ ];
              };
            };
          });
      };
    };
  };

  config =
    let
      cfg = config.slb.security;
      installedCredsPath = "/etc/gcp-instance-creds.json";
      credsPath = "/run/gcp-instance-creds.json";
      infoPath = "/run/gcp-instance-info.env";
      mkSecretService =
        name: conf:
        let
          mode = if conf.group == null then "0600" else "0640";
          group = if conf.group == null then "root" else conf.group;
          targetPath = if conf.outPath != null then conf.outPath else "/run/credstore/${name}";
          tmpl =
            if conf.template == null then
              assert conf.secretPath != null;
              pkgs.writeText "secret-${name}-tmpl" "{{gcpSecret \"${conf.secretPath}\"}}"
            else
              assert conf.secretPath == null;
              conf.template;
        in
        {
          description = "Fetch secret ${name}";
          wantedBy = [ "multi-user.target" ];
          inherit (conf) before;
          after = [ "instance-key.service" ] ++ conf.after;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true; # Stay "active" so bindsTo works
          };
          environment.GOOGLE_APPLICATION_CREDENTIALS = credsPath;

          script =
            if conf.outPath != null then
              ''
                [[ -f ${conf.outPath} ]] || install -m 0600 /dev/null ${conf.outPath}
                chown ${conf.owner}:${group} ${conf.outPath}
                chmod ${mode} ${conf.outPath}
                ${mypkgs.gcp-secret-subst}/bin/gcp-secret-subst ${tmpl} > ${conf.outPath}
              ''
            else
              ''
                mkdir -p /run/credstore
                install -m 0400 /dev/null ${targetPath}
                ${mypkgs.gcp-secret-subst}/bin/gcp-secret-subst ${tmpl} > ${targetPath}
              '';
        };

      # Append the given secret service to the target's bindsTo, after, and requires lists
      addBindsTo =
        acc: secretUnit: targetUnit:
        let
          unitName = lib.removeSuffix ".service" targetUnit;
        in
        acc
        // {
          ${unitName} = (acc.${unitName} or { }) // {
            bindsTo = (acc.${unitName}.bindsTo or [ ]) ++ [ secretUnit ];
            after = (acc.${unitName}.after or [ ]) ++ [ secretUnit ];
            requires = (acc.${unitName}.requires or [ ]) ++ [ secretUnit ];
          };
        };

      # Get a flattened list of {secret, target} pairs from restartUnits options
      allRestartBindings =
        secrets:
        lib.concatLists (
          lib.mapAttrsToList (
            name: conf:
            map (unit: {
              secretUnit = "secret-${name}.service";
              targetUnit = unit;
            }) conf.restartUnits
          ) secrets
        );

      mkRestartBindings =
        secrets:
        lib.foldl' (acc: { secretUnit, targetUnit }: addBindsTo acc secretUnit targetUnit) { } (
          allRestartBindings secrets
        );

      # For secrets without outPath, inject LoadCredential into units listed in restartUnits
      addCredentialBinding =
        acc: secretName: targetUnit:
        let
          unitName = lib.removeSuffix ".service" targetUnit;
        in
        acc
        // {
          ${unitName} = (acc.${unitName} or { }) // {
            serviceConfig = (acc.${unitName}.serviceConfig or { }) // {
              LoadCredential = (acc.${unitName}.serviceConfig.LoadCredential or [ ]) ++ [ secretName ];
            };
          };
        };

      allCredentialBindings =
        secrets:
        lib.concatLists (
          lib.mapAttrsToList (
            name: conf:
            if conf.outPath == null then
              map (unit: {
                secretName = name;
                targetUnit = unit;
              }) conf.restartUnits
            else
              [ ]
          ) secrets
        );

      mkCredentialBindings =
        secrets:
        lib.foldl' (acc: { secretName, targetUnit }: addCredentialBinding acc secretName targetUnit) { } (
          allCredentialBindings secrets
        );
    in
    lib.mkIf cfg.enable {
      users.groups = {
        gcpinstance = {
          name = "gcp-instance-users";
          members = [ "acme" ];
        };
      };

      systemd.services = {
        "instance-key" = {
          description = "decrypt instance key";
          wantedBy = [ "multi-user.target" ];
          before = [ "acme-${cfg.acmeHostName}.service" ]; # TODO hack
          serviceConfig = {
            Type = "oneshot";
            UMask = 337;
          };

          script = ''
            if [ -f "${installedCredsPath}" ]; then
              # Install a hand-installed instance key
              install -m 0440 -g ${config.users.groups.gcpinstance.name} /dev/null ${credsPath}
              cat ${installedCredsPath} > ${credsPath}
            else
              echo "No GCP instance key found at ${installedCredsPath}" >&2
              exit 1
            fi

            # Make a handy file with GCP project and service account info
            install -m 0444 /dev/null ${infoPath}
            cat >${infoPath} <<EOF
            GCE_PROJECT=$(${pkgs.jq}/bin/jq -r .project_id <${credsPath})
            GCE_SERVICE_ACCOUNT_FILE=${credsPath}
            EOF
          '';
        };
      }
      // (lib.mapAttrs' (
        name: value: lib.nameValuePair ("secret-" + name) (mkSecretService name value)
      ) cfg.secrets)
      // (lib.recursiveUpdate (mkRestartBindings cfg.secrets) (mkCredentialBindings cfg.secrets));

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "lucas@bergmans.us";
          dnsProvider = "gcloud";
          environmentFile = infoPath;
        };

        certs."${cfg.acmeHostName}" = { };
      };
    };
}
