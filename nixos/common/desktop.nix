{
  config,
  pkgs,
  ...
}: {
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

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
