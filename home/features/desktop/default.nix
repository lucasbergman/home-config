{
  pkgs,
  nixpkgs-unstable,
  ...
}: {
  home.packages = with pkgs; [
    alacritty
    corefonts
    dejavu_fonts
    google-fonts
    kitty
    mesa
    noto-fonts
    waypipe

    nixpkgs-unstable.google-chrome
  ];

  programs.kitty = {
    enable = true;
    font.name = "Noto Sans Mono";
    font.size = 18;
  };
}
