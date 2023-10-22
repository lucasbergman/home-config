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

  slb.backups = {
    gcsPath = "/cheddar";
    backupPaths = ["/data"];
    passwordSecretID = "projects/bergmans-services/secrets/restic-password-cheddar/versions/1";
  };

  slb.security.gcpInstanceKeyPath = ./gcp-instance-key.json;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
