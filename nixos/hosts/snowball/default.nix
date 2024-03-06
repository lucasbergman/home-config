{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../common/global
    ../../common/users
    ../../common/desktop.nix
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.network.networks."10-lan" = {
    matchConfig.Name = "enp3s0";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = true;
    };
  };

  networking = {
    hostName = "snowball";
    domain = "bergman.house";
    wireless.enable = false;
  };

  # This is a desktop
  time.timeZone = "America/Chicago";
  slb.security.enable = false;

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  security.polkit.enable = true;
  hardware.opengl.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
