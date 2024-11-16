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

  programs.swaylock.enable = true;
  services.mako.enable = true;
  services.swayidle.enable = true;

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
