{
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
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  security.pam.services.swaylock = { };
  programs.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
  };
}
