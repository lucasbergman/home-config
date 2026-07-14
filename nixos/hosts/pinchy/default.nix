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

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  environment.systemPackages = [
    mypkgs.hermes-agent
  ];

  slb.backups.enable = false;
  slb.nebula.enable = true;

  services.resolved.extraConfig = ''
    MulticastDNS=no
  '';

  slb.security = {
    enable = true;
    gcpInstanceKeyPath = null;
  };

  systemd.services.hermes-gateway = {
    description = "Hermes Agent Gateway";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      HOME = "/home/hermes";
    };
    serviceConfig = {
      User = "hermes";
      Group = "hermes";
      WorkingDirectory = "/home/hermes";
      ExecStart = "${mypkgs.hermes-agent}/bin/hermes gateway";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
