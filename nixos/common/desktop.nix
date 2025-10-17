{
  pkgs,
  pkgs-unstable,
  ...
}:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  programs.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
  };
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };
}
