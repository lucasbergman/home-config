{
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./securenets.nix
    ./ssh.nix
  ];

  nix = {
    # Add each flake input as a registry to make nix3 commands consistent with the flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;

      # Let anyone in the wheel group have extra rights with Nix. This is
      # needed in particular for doing nixos-rebuild over SSH to a machine
      # that doesn't allow remote logins from root.
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  time.timeZone = lib.mkDefault "Etc/UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # YOLO
  networking.firewall.enable = false;
}
