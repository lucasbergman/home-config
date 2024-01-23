{...}: {
  imports = [
    ./global
    ./features/desktop
    ./features/desktop/moneydance.nix
    ./features/desktop/wayland.nix
  ];
}
