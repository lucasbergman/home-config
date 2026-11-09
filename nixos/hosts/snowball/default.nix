{
  ...
}:
{
  imports = [
    ../../common/global
    ../../common/users
    ../../common/users/audrey.nix
    ../../common/users/resa.nix
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

  slb.nebula.enable = true;

  # This is a desktop
  time.timeZone = "America/Chicago";

  slb.backups = {
    gcsPath = "/snowball";
    backupPaths = [
      "/home/lucas/Moneydance"
      "/home/lucas/hack"
      "/home/lucas/mail"
    ];
    passwordSecretID = "projects/bergmans-services/secrets/restic-password-snowball/versions/1";
    exclude = [
      ".terraform"
      "node_modules"
    ];
  };

  slb.qemu.enable = true;

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  security.polkit.enable = true;
  hardware.graphics.enable = true;

  # Disable system sleep/suspend. Desktop environments like KDE Plasma
  # enable automatic sleep by default when idle. Experimentally, this
  # desktop has trouble resuming properly.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
