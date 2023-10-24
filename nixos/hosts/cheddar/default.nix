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
    ../../common/users
    ../../linode
    ./hardware-configuration.nix
    ./services
  ];

  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
  };

  networking = {
    hostName = "cheddar";
    domain = "bergmans.us";
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
