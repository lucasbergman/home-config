{
  config,
  lib,
  pkgs,
  ...
}: {
  options = with lib; {
    slb.security = {
      acmeHostName = mkOption {
        type = types.str;
        description = "Host name (FQDN) for this host's main ACME certificate";
        default = let n = config.networking; in "${n.hostName}.${n.domain}";
      };

      # TODO: Add checks to make sure this is defined
      gcpInstanceKeyPath = mkOption {
        type = types.path;
        description = "Google Cloud service account encrypted private key path";
      };
    };
  };

  config = let
    cfg = config.slb.security;
  in {
    users.groups = {
      gcpinstance = {
        name = "gcp-instance-users";
        members = ["acme"];
      };
    };

    systemd.services."instance-key" = {
      description = "decrypt instance key";
      wantedBy = ["multi-user.target"];
      before = ["acme-${cfg.acmeHostName}.service"]; # TODO hack
      serviceConfig = {
        Type = "oneshot";
        UMask = 0337;
      };

      script = with builtins; let
        # Use the host's EdDSA 25519 key for SOPS
        hostKeyPaths = map (getAttr "path") config.services.openssh.hostKeys;
        edDSAKey = lib.lists.findSingle (lib.hasInfix "ed25519") "" "" hostKeyPaths;
        sopsKeyPath = assert edDSAKey != ""; edDSAKey;
      in ''
        install -m 0440 -g ${config.users.groups.gcpinstance.name} \
          /dev/null /run/gcp-instance-creds.json
        env SOPS_AGE_KEY=$(${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < "${sopsKeyPath}") \
          ${pkgs.sops}/bin/sops --decrypt ${cfg.gcpInstanceKeyPath} > /run/gcp-instance-creds.json

        install -m 0444 /dev/null /run/gcp-instance-info.env
        cat >/run/gcp-instance-info.env <<EOF
        GCE_PROJECT=$(${pkgs.jq}/bin/jq -r .project_id </run/gcp-instance-creds.json)
        GCE_SERVICE_ACCOUNT_FILE=/run/gcp-instance-creds.json
        EOF
      '';
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "lucas@bergmans.us";
        dnsProvider = "gcloud";
        credentialsFile = "/run/gcp-instance-info.env";
      };

      certs."${cfg.acmeHostName}" = {};
    };
  };
}
