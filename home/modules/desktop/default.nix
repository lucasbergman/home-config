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
      pkgs.brightnessctl
      pkgs.grim
      pkgs.hyprpicker
      pkgs.libnotify
      pkgs.pavucontrol
      pkgs.playerctl
      pkgs.slurp
      pkgs.wf-recorder
      pkgs.wl-clipboard

      (mypkgs.moneydance.override {
        clientJdk = pkgs.openjdk21.override { enableJavaFX = true; };
      })
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      settings = import ./hyprland.nix;

      # Installed at the NixOS level
      package = null;
      portalPackage = null;
    };

    programs.alacritty = {
      enable = true;
      settings = {
        font.size = 14;
        window.padding = {
          x = 12;
          y = 12;
        };
      };
    };

    programs.ghostty = {
      enable = true;
      settings = {
        theme = "TokyoNight";
        font-family = "JetBrainsMono NF";
        font-size = 14;
        window-padding-x = 12;
        window-padding-y = 12;
        background-opacity = 0.95;
        cursor-style = "block";
        cursor-style-blink = false;
      };
    };

    programs.wofi = {
      enable = true;
      settings = {
        width = 480;
        height = 360;
        prompt = "Search...";
        show = "run";
        mode = "run";
        insensitive = true;
        allow_images = true;
        image_size = 24;
      };
      style = builtins.readFile ./wofi.css;
    };

    services.mako = {
      enable = true;
      settings = {
        font = "JetBrainsMono Nerd Font 11";
        background-color = "#1a1b26fa";
        text-color = "#c0caf5";
        border-color = "#7aa2f7";
        border-size = 2;
        border-radius = 10;
        padding = "12";
        default-timeout = 5000;
        progress-color = "over #7aa2f7";
      };
    };
  };
}
