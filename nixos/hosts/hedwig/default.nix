let
  slb.sshPubKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIF3xjVDP5aujMnlsdemCWfMicDJLQBPKl9vwzceAo8V lucas@errol"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDoNx5swAaaZgjoZ2QYnoHwgt7lBu3vbrcwWv5W/0sl8MSctF2c8dN7/Hquyk1TJ1FuwD6cIbktCZHSu2pmOmfVhzABspmL1+U89nwzS8aJTIaaSHdouvoQ1eHHSW4z01/KWXO+awd1vX+TU67pLB2I/N3nrYaLZsMgxg/tugxIkrRQZoEwJ2Q4uqIQnZ9lRamloKDoDa9ofMLgJHFQ56SRUfBNSDehTdowPUg6NwpZbfiCTYQlpXDer3IKpW7HeEwJnYJ5JPRbbVQ6n+6ULLkKcrpj5qdNTLL+V7SKDvMI44vyzHBkwY3DzNJcyPL8RwHNlAq2JrYs5kfe62YcDVP/ lucas@hedwig"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxQDnZ2MZ0Q+APiJ7u3MnJ+T23uNTkwyf5R6YJwzX49 lucas@hedwig"
  ];
in
  {
    inputs,
    outputs,
    lib,
    config,
    pkgs,
    ...
  }: {
    imports = [
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

      users.root.openssh.authorizedKeys.keys = slb.sshPubKeys;

      users.lucas = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        openssh.authorizedKeys.keys = slb.sshPubKeys;
      };
    };

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = false;
      };
      hostKeys = [
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
    };

    users.groups = {
      gcpinstance = {
        name = "gcp-instance-users";
        members = ["acme"];
      };
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "23.05";
  }
