{...}: {
  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      terminal = "kitty";
      startup = [{command = "kitty";}];
    };
  };

  # Magic value to make AWT (basically all Java desktop) rendering work on
  # tiling window managers, including Sway and Hyprland.
  #
  # TODO: Set this stuff in a sway wrapper script
  home.sessionVariables."_JAVA_AWT_WM_NONREPARENTING" = "1";
}
