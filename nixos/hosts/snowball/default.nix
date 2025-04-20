{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../common/global
    ../../common/users

    inputs.nixos-wsl.nixosModules.wsl
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  slb.securenet = {
    enable = false;
    network = "bergnet";
    privateKeyPath = "/etc/bergmans-wg-key";
  };

  systemd.network.networks."10-lan" = {
    matchConfig.Name = "eth0";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = true;
    };
  };

  networking = {
    hostName = "snowball-wsl";
    domain = "bergman.house";
    wireless.enable = false;
  };

  # This is a desktop
  time.timeZone = "America/Chicago";
  slb.security.enable = false;
  slb.backups.enable = false;

  # This is running under WSL
  wsl.enable = true;
  nixpkgs.hostPlatform = "x86_64-linux";

  security.polkit.enable = true;
  hardware.opengl.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
