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

    pkgs-unstable.google-chrome
  ];

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
    config =
      let
        fonts = {
          names = [ "DejaVu Sans" ];
          size = 16.0;
        };
      in
      {
        inherit fonts;
        modifier = "Mod4";
        terminal = "alacritty";
        startup = [ { command = "alacritty"; } ];
        bars = [
          {
            inherit fonts;
            position = "top";
            statusCommand = "while date +'%a %F %H:%M'; do sleep 5; done";
          }
        ];
      };
  };

  programs.swaylock = {
    enable = true;
    settings = {
      ignore-empty-password = true;
      show-failed-attempts = true;
      color = "111111";
    };
  };

  services.mako.enable = true;

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 180;
        command = "${pkgs.swaylock}/bin/swaylock --daemonize";
      }
    ];
  };

  xdg.portal = {
    enable = true;

    # TODO: This is needlessly blunt
    #
    # I wonder if we can get away with just using the GTK backend for everything
    # except (say) GNOME for screencasting with Google Chrome, etc.
    config.common.default = [
      "gnome"
      "gtk"
      "wlr"
    ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font.size = 18;
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode;
    extensions = with pkgs-unstable.vscode-extensions; [
      bbenoist.nix
      kamadorueda.alejandra
    ];
  };
}
