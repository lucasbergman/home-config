{ pkgs, pkgs-unstable, ... }:
{
  home.packages = [
    pkgs.dejavu_fonts
    pkgs.google-fonts
    pkgs.noto-fonts

    pkgs.grim
    pkgs.slurp
    pkgs.wf-recorder
    pkgs.wl-clipboard

    pkgs-unstable.discord
    pkgs-unstable.google-chrome
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = import ./hyprland.nix;

    # Installed at the NixOS level
    package = null;
    portalPackage = null;
  };

  programs.kitty.enable = true;
  programs.wofi.enable = true;

  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode;
    extensions = with pkgs-unstable.vscode-extensions; [
      bbenoist.nix
      kamadorueda.alejandra
    ];
  };
}
