{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../common/cloudbackup.nix
    ../../common/nginx.nix
    ../../common/global
    ../../common/users/lucas
    ../../linode
    ./hardware-configuration.nix
    ./services
  ];

  nix = {
    # Add each flake input as a registry to make nix3 commands consistent with the flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
  };

  networking = {
    firewall.enable = false;

    hostName = "cheddar";
    domain = "bergmans.us";
  };

  time.timeZone = "Etc/UTC";

  security.sudo.wheelNeedsPassword = false;
  users = {
    # Users can only be made declaratively
    mutableUsers = false;
  };

  users.groups = {
    gcpinstance = {
      name = "gcp-instance-users";
      members = ["acme"];
    };
  };

  systemd.services."instance-key" = let
    keypath = ./gcp-instance-key.json;
  in {
    description = "decrypt instance key";
    wantedBy = ["multi-user.target"];
    before = ["acme-cheddar.bergmans.us.service"]; # TODO hack
    serviceConfig = {
      Type = "oneshot";
      UMask = 0337;
    };

    script = ''
      install -m 0440 -g "${config.users.groups.gcpinstance.name}" \
        /dev/null /run/gcp-instance-creds.json
      env SOPS_AGE_KEY=$("${pkgs.ssh-to-age}/bin/ssh-to-age" -private-key \
          < /etc/ssh/ssh_host_ed25519_key) \
        "${pkgs.sops}/bin/sops" --decrypt "${keypath}" > /run/gcp-instance-creds.json

      install -m 0444 /dev/null /run/gcp-instance-info.env
      cat >/run/gcp-instance-info.env <<EOF
      GCE_PROJECT=$("${pkgs.jq}/bin/jq" -r .project_id </run/gcp-instance-creds.json)
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

    certs."cheddar.bergmans.us" = {};
  };

  slb.backups = {
    gcsPath = "/cheddar";
    backupPaths = ["/data"];
    passwordSecretID = "projects/bergmans-services/secrets/restic-password-cheddar/versions/1";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
