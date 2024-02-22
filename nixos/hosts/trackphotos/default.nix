{
  inputs,
  outputs,
  lib,
  modulesPath,
  config,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
    ../../common/global
    ../../common/users
    ./services
  ];

  slb.security.gcpInstanceKeyPath = ./gcp-instance-key.json;

  networking = {
    hostName = "trackphotos";
    domain = "bergmans.us";
  };

  systemd.network = {
    networks."10-wan" = {
      matchConfig.Name = "ens3";
      networkConfig.DHCP = "ipv4";

      # This link must be routable as a dependency of network-online.target
      linkConfig.RequiredForOnline = "routable";
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
