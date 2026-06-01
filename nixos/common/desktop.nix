{
  pkgs,
  pkgs-unstable,
  mypkgs,
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
  security.pam.services.hyprlock = { };
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };

  environment.systemPackages = [
    pkgs-unstable.discord
    pkgs-unstable.google-chrome
    pkgs-unstable.jetbrains.idea
    pkgs-unstable.vscode-fhs
    mypkgs.google-antigravity-ide
  ];

  fonts.packages = with pkgs; [
    dejavu_fonts
    font-awesome
    google-fonts
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
