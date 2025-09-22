{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  mypkgs,
  ...
}:
{
  config = lib.mkIf config.slb.isDesktop {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Pander to Electron on Wayland
    };

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

      (mypkgs.moneydance.override {
        clientJdk = pkgs.jetbrains.jdk;
        baseJvmFlags = [ "-client" ];
        jvmFlags = [ "-Dawt.toolkit.name=WLToolkit" ];
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
    programs.kitty.enable = true;
    programs.wofi.enable = true;
  };
}
