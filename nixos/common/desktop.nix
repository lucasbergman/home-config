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
  programs.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
  };
}
