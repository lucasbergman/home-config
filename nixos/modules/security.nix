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

      # TODO: Add checks to make sure this is defined
      gcpInstanceKeyPath = lib.mkOption {
        type = lib.types.path;
        description = "Google Cloud service account encrypted private key path";
      };

      secrets = lib.mkOption {
        default = { };
        type =
          with lib.types;
          attrsOf (submodule {
            options = {
              outPath = lib.mkOption {
                description = "Output path for secret material";
                type = path;
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
              before = lib.mkOption {
                description = "List of systemd units that should be delayed until after secrets are written";
                type = listOf str;
                default = [ ];
              };
              owner = lib.mkOption {
                description = "User that will own the output file";
                type = str;
                default = "root";
              };
              group = lib.mkOption {
                description = "Group that will own the output file; if null, output file is not group-readable";
                type = nullOr str;
                default = null;
              };
            };
          });
      };
    };
  };

  config =
    let
      cfg = config.slb.security;
      credsPath = "/run/gcp-instance-creds.json";
      infoPath = "/run/gcp-instance-info.env";
      mkSecretService =
        name: conf:
        let
          mode = if conf.group == null then "0600" else "0640";
          group = if conf.group == null then "root" else conf.group;
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
          after = [ "instance-key.service" ];
          serviceConfig.Type = "oneshot";
          environment.GOOGLE_APPLICATION_CREDENTIALS = credsPath;

          script = ''
            [[ -f ${conf.outPath} ]] || install -m 0600 /dev/null ${conf.outPath}
            chown ${conf.owner}:${group} ${conf.outPath}
            chmod ${mode} ${conf.outPath}
            ${mypkgs.gcp-secret-subst}/bin/gcp-secret-subst ${tmpl} > ${conf.outPath}
          '';
        };
    in
    lib.mkIf cfg.enable {
      users.groups = {
        gcpinstance = {
          name = "gcp-instance-users";
          members = [ "acme" ];
        };
      };

      systemd.services =
        {
          "instance-key" = {
            description = "decrypt instance key";
            wantedBy = [ "multi-user.target" ];
            before = [ "acme-${cfg.acmeHostName}.service" ]; # TODO hack
            serviceConfig = {
              Type = "oneshot";
              UMask = 337;
            };

            script =
              with builtins;
              let
                # Use the host's EdDSA 25519 key for SOPS
                hostKeyPaths = map (getAttr "path") config.services.openssh.hostKeys;
                edDSAKey = lib.lists.findSingle (lib.hasInfix "ed25519") "" "" hostKeyPaths;
                sopsKeyPath =
                  assert edDSAKey != "";
                  edDSAKey;
              in
              ''
                install -m 0440 -g ${config.users.groups.gcpinstance.name} /dev/null ${credsPath}
                env SOPS_AGE_KEY=$(${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < "${sopsKeyPath}") \
                  ${pkgs.sops}/bin/sops --decrypt ${cfg.gcpInstanceKeyPath} > ${credsPath}

                install -m 0444 /dev/null ${infoPath}
                cat >${infoPath} <<EOF
                GCE_PROJECT=$(${pkgs.jq}/bin/jq -r .project_id <${credsPath})
                GCE_SERVICE_ACCOUNT_FILE=${credsPath}
                EOF
              '';
          };
        }
        // lib.mapAttrs' (
          name: value: lib.nameValuePair ("secret-" + name) (mkSecretService name value)
        ) cfg.secrets;

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "lucas@bergmans.us";
          dnsProvider = "gcloud";
          credentialsFile = infoPath;
        };

        certs."${cfg.acmeHostName}" = { };
      };
    };
}
