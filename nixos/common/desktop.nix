{
  config,
  pkgs,
  ...
}: {
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      dejavu_fonts
      google-fonts
      noto-fonts

      alacritty
      dmenu
      grim
      mako
      slurp
      swayidle
      swaylock
      wf-recorder
      wl-clipboard
    ];
    extraSessionCommands = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
    '';
  };
}
