{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../common/global
    ../../common/users
    ../../linode
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "spot";
    domain = "bergmans.us";
  };

  networking.nftables.enable = true;
  networking.firewall.enable = true;

  slb.backups.enable = false;
  slb.security.enable = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
