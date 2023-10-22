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
    ../../common/users/lucas
    ./hardware-configuration.nix
  ];

  nix = {
    # Add each flake input as a registry to make nix3 commands consistent with the flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  fileSystems = {
    "/nix" = {
      device = "rpool/ephemeral/nix";
      fsType = "zfs";
    };
    "/home" = {
      device = "rpool/safe/home";
      fsType = "zfs";
    };
    "/persist" = {
      device = "rpool/safe/persist";
      fsType = "zfs";
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # https://grahamc.com/blog/nixos-on-zfs/
  boot.kernelParams = ["elevator=none"];

  networking = {
    hostName = "hedwig";
    domain = "bergman.house";

    firewall.enable = false;
    wireless.enable = false;

    # Required for ZFS because reasons
    hostId = "f7b88e11";
  };

  # Use systemd-networkd for address configuration
  networking = {
    useDHCP = false;
    networkmanager.enable = false;
  };
  systemd.network.enable = true;

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "enp3s0";
    address = ["192.168.101.3/24"];
    routes = [{routeConfig.Gateway = "192.168.101.1";}];
    linkConfig.RequiredForOnline = "routable";
  };

  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo.wheelNeedsPassword = false;
  users = {
    # Users can only be made declaratively
    mutableUsers = false;
  };

  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/persist/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  slb.security.gcpInstanceKeyPath = ./gcp-instance-key.json;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
