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
    ../../common/cloudbackup.nix
    ../../common/gcplogs.nix
    ../../common/nginx.nix
    ./hardware-configuration.nix
    ./services
  ];

  nixpkgs.config.allowUnfree = true;

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
    "/storage/media" = {
      device = "storage/media";
      fsType = "zfs";
    };
    "/storage/users" = {
      device = "storage/users";
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

    wireless.enable = false;

    # Required for ZFS because reasons
    hostId = "f7b88e11";
  };

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "enp3s0";
    address = ["192.168.101.3/24"];
    routes = [{routeConfig.Gateway = "192.168.101.1";}];
    linkConfig.RequiredForOnline = "routable";
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

  slb.backups = {
    gcsPath = "/hedwig";
    backupPaths = [
      "/persist"
      "/home/lucas"

      # Department of tragically hard-coded systemd service data directories
      "/var/lib/prometheus2"
      "/var/lib/unifi"
    ];
    passwordSecretID = "projects/bergmans-services/secrets/restic-password-hedwig/versions/1";
    exclude = [
      ".terraform"
      "node_modules"
    ];
  };

  slb.gcplogs = {
    location = "home:chateau";
    included-units = [
      "prometheus.service"
      "sshd.service"
      "systemd-journald.service"
      "systemd-logind.service"
      "systemd-networkd.service"
      "systemd-oomd.service"
      "systemd-resolved.service"
      "systemd-timesyncd.service"
      "systemd-udevd.service"
      "unifi.service"
      "zfs-zed.service"
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
