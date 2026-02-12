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
    ./services/nebula.nix
  ];

  networking = {
    hostName = "spot";
    domain = "bergmans.us";
  };

  networking.nftables.enable = true;
  networking.firewall.enable = true;

  slb.backups.enable = false;

  # Turn off mDNS; its port conflicts with Nebula DNS
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
