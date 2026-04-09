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
    hostName = "pinchy";
    domain = "bergmans.us";
  };

  networking.nftables.enable = true;
  networking.firewall.enable = true;

  slb.backups.enable = false;
  slb.nebula.enable = true;

  services.resolved.extraConfig = ''
    MulticastDNS=no
  '';

  slb.security = {
    enable = true;
    gcpInstanceKeyPath = null;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
