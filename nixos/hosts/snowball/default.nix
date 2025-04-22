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

  slb.securenet = {
    enable = false;
    network = "bergnet";
    privateKeyPath = "/etc/bergmans-wg-key";
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
  wsl.defaultUser = "lucas";
  slb.networking.enableSystemdNetworkd = false; # Windows handles the network
  nixpkgs.hostPlatform = "x86_64-linux";

  security.polkit.enable = true;
  hardware.graphics.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
