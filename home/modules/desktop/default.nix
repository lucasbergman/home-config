{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  mypkgs,
  ...
}:
{
  imports = [
    ./hypridle.nix
    ./hyprlock.nix
    ./waybar.nix
  ];

  config = lib.mkIf config.slb.isDesktop {
    home.sessionVariables = {
      # Pander to Electron on Wayland
      NIXOS_OZONE_WL = "1";

      # Pander to Java/Swing on XWayland
      _JAVA_AWT_WM_NONREPARENTING = "1";
      GDK_SCALE = "2";
    };

    fonts.fontconfig.enable = true;

    home.packages = [
      pkgs.dejavu_fonts
      pkgs.font-awesome
      pkgs.google-fonts
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.noto-fonts
      pkgs.noto-fonts-color-emoji

      pkgs.grim
      pkgs.slurp
      pkgs.wf-recorder
      pkgs.wl-clipboard

      pkgs-unstable.discord
      pkgs-unstable.google-chrome

      (mypkgs.moneydance.override {
        clientJdk = pkgs.openjdk21.override { enableJavaFX = true; };
      })
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      settings = import ./hyprland.nix;

      # Installed at the NixOS level
      package = null;
      portalPackage = null;
    };

    programs.alacritty = {
      enable = true;
      settings = {
        font.size = 18;
      };
    };
    programs.ghostty = {
      enable = true;
      settings = {
        theme = "Adwaita Dark";
        font-family = "JetBrainsMono NF";
        font-size = 14;
      };
    };
    programs.wofi.enable = true;
  };
}
