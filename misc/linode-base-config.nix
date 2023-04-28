# Simple NixOS configuration file to bootstrap a Linode installation.
# See also <https://www.linode.com/docs/guides/install-nixos-on-linode/>,
# but note that when you boot the installer image, you have to smack <tab>
# and add `console=ttyS0` on the end of the kernel params.
{...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    forceInstall = true;
    copyKernels = true;
    fsIdentifier = "label";
    extraConfig = ''
      serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
      terminal_input serial;
      terminal_output serial
    '';
  };
  boot.loader.timeout = 10;
  boot.kernelParams = ["console=ttyS0,19200n8"];

  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false;
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxQDnZ2MZ0Q+APiJ7u3MnJ+T23uNTkwyf5R6YJwzX49"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFSo2W6U45Lvb3wegccTAWNsVXuy0m9jI8OMN4Cv3NH"
    ];
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };
  networking.firewall.enable = false;
  system.copySystemConfiguration = true;
  system.stateVersion = "22.11";
}
