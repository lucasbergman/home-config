{
  lib,
  config,
  pkgs,
  mypkgs,
  ...
}:
{
  imports = [
    ../../common/global
    ../../common/users
    ../../common/users/hermes.nix
    ../../linode
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "pinchy";
    domain = "bergmans.us";
  };

  networking.nftables.enable = true;
  networking.firewall.enable = true;

  users.users.hermes.linger = true;

  services.hermes-agent = {
    enable = true;
    createUser = false;
    user = "hermes";
    group = "hermes";
    stateDir = "/home/hermes";
    workingDirectory = "/home/hermes";
    addToSystemPackages = true;
  };

  slb.backups.enable = false;
  slb.nebula.enable = true;

  services.resolved.settings = {
    Resolve.MulticastDNS = "no";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
