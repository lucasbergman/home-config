{
  monitor = ",preferred,auto,auto";
  "$terminal" = "ghostty";
  "$menu" = "wofi --show run --prompt 'Search...'";

  xwayland.force_zero_scaling = true;

  general = {
    gaps_in = 4;
    gaps_out = 8;
    border_size = 2;

    # Tokyo Night vibrant gradient borders
    "col.active_border" = "rgba(7aa2f7ee) rgba(bb9af7ee) 45deg";
    "col.inactive_border" = "rgba(414868aa)";

    resize_on_border = true;
    allow_tearing = false;
    layout = "dwindle";
  };

  decoration = {
    rounding = 10;
    rounding_power = 2;
    active_opacity = 1.0;
    inactive_opacity = 0.96;

    shadow = {
      enabled = true;
      range = 15;
      render_power = 3;
      color = "rgba(00000055)";
      offset = "0 2";
    };

    blur = {
      enabled = true;
      size = 6;
      passes = 3;
      new_optimizations = true;
      xray = false;
      vibrancy = 0.2;
    };
  };

  group = {
    "col.border_active" = "rgba(7aa2f7ee)";
    "col.border_inactive" = "rgba(414868aa)";
    groupbar = {
      font_size = 10;
      font_family = "JetBrainsMono Nerd Font";
      text_color = "rgb(c0caf5)";
      "col.active" = "rgba(7aa2f7b3)";
      "col.inactive" = "rgba(24283b80)";
      height = 18;
      indicator_height = 2;
    };
  };

  animations = {
    enabled = true;

    bezier = [
      "easeOutQuint,0.23,1,0.32,1"
      "easeInOutCubic,0.65,0.05,0.36,1"
      "linear,0,0,1,1"
      "almostLinear,0.5,0.5,0.75,1.0"
      "quick,0.15,0,0.1,1"
    ];

    animation = [
      "global, 1, 10, default"
      "border, 1, 5.39, easeOutQuint"
      "windows, 1, 3.8, easeOutQuint"
      "windowsIn, 1, 3.8, easeOutQuint, popin 87%"
      "windowsOut, 1, 1.8, linear, popin 87%"
      "fadeIn, 1, 1.73, almostLinear"
      "fadeOut, 1, 1.46, almostLinear"
      "fade, 1, 3.03, quick"
      "layers, 1, 3.81, easeOutQuint"
      "layersIn, 1, 4, easeOutQuint, fade"
      "layersOut, 1, 1.5, linear, fade"
      "fadeLayersIn, 1, 1.79, almostLinear"
      "fadeLayersOut, 1, 1.39, almostLinear"
      "workspaces, 1, 2.5, easeOutQuint, slide"
      "specialWorkspace, 1, 3, easeOutQuint, slidevert"
    ];
  };

  dwindle = {
    preserve_split = true;
    force_split = 2;
  };

  master = {
    new_status = "master";
  };

  misc = {
    disable_hyprland_logo = true;
    disable_splash_rendering = true;
    mouse_move_enables_dpms = true;
    key_press_enables_dpms = true;
    focus_on_activate = true;
    initial_workspace_tracking = 0;
  };

  cursor = {
    hide_on_key_press = true;
    warp_on_change_workspace = true;
  };

  input = {
    kb_layout = "us";
    follow_mouse = 1;
    sensitivity = 0;
    repeat_rate = 40;
    repeat_delay = 250;

    touchpad = {
      natural_scroll = true;
      tap-to-click = true;
      scroll_factor = 0.4;
    };
  };

  "$mainMod" = "SUPER";

  bind = [
    # Applications & Shell
    "$mainMod, Return, exec, $terminal"
    "$mainMod, Space, exec, $menu"
    "$mainMod, R, exec, $menu"
    "$mainMod, Escape, exec, loginctl lock-session"
    "$mainMod SHIFT, Q, exit,"

    # Window Management
    "$mainMod, Q, killactive,"
    "$mainMod, C, killactive,"
    "$mainMod, F, fullscreen, 0"
    "$mainMod, M, fullscreen, 1"
    "$mainMod ALT, F, fullscreen, 1"
    "$mainMod, V, togglefloating,"
    "$mainMod, T, togglefloating,"
    "$mainMod, P, pseudo,"
    "$mainMod, J, layoutmsg, togglesplit"
    "$mainMod, Backslash, layoutmsg, togglesplit"

    # Groups / Tabs
    "$mainMod, G, togglegroup,"
    "$mainMod ALT, G, moveoutofgroup,"
    "$mainMod ALT, Tab, changegroupactive, f"
    "$mainMod ALT SHIFT, Tab, changegroupactive, b"

    # Window Focus (Vi-keys & Arrows)
    "$mainMod, H, movefocus, l"
    "$mainMod, L, movefocus, r"
    "$mainMod, K, movefocus, u"
    "$mainMod, Left, movefocus, l"
    "$mainMod, Right, movefocus, r"
    "$mainMod, Up, movefocus, u"
    "$mainMod, Down, movefocus, d"

    # Window Swap / Move (Vi-keys & Arrows)
    "$mainMod SHIFT, H, movewindow, l"
    "$mainMod SHIFT, L, movewindow, r"
    "$mainMod SHIFT, K, movewindow, u"
    "$mainMod SHIFT, J, movewindow, d"
    "$mainMod SHIFT, Left, movewindow, l"
    "$mainMod SHIFT, Right, movewindow, r"
    "$mainMod SHIFT, Up, movewindow, u"
    "$mainMod SHIFT, Down, movewindow, d"

    # Window Resizing (Vi-keys & Arrows)
    "$mainMod CTRL, H, resizeactive, -40 0"
    "$mainMod CTRL, L, resizeactive, 40 0"
    "$mainMod CTRL, K, resizeactive, 0 -40"
    "$mainMod CTRL, J, resizeactive, 0 40"
    "$mainMod CTRL, Left, resizeactive, -40 0"
    "$mainMod CTRL, Right, resizeactive, 40 0"
    "$mainMod CTRL, Up, resizeactive, 0 -40"
    "$mainMod CTRL, Down, resizeactive, 0 40"

    # Cycle Windows
    "ALT, Tab, cyclenext,"
    "ALT SHIFT, Tab, cyclenext, prev"

    # Scratchpad (Special Workspace)
    "$mainMod, S, togglespecialworkspace, magic"
    "$mainMod, grave, togglespecialworkspace, magic"
    "$mainMod SHIFT, S, movetoworkspacesilent, special:magic"
    "$mainMod SHIFT, grave, movetoworkspacesilent, special:magic"

    # Workspace Switching
    "$mainMod, 1, workspace, 1"
    "$mainMod, 2, workspace, 2"
    "$mainMod, 3, workspace, 3"
    "$mainMod, 4, workspace, 4"
    "$mainMod, 5, workspace, 5"
    "$mainMod, 6, workspace, 6"
    "$mainMod, 7, workspace, 7"
    "$mainMod, 8, workspace, 8"
    "$mainMod, 9, workspace, 9"

    # Move active window to workspace
    "$mainMod SHIFT, 1, movetoworkspace, 1"
    "$mainMod SHIFT, 2, movetoworkspace, 2"
    "$mainMod SHIFT, 3, movetoworkspace, 3"
    "$mainMod SHIFT, 4, movetoworkspace, 4"
    "$mainMod SHIFT, 5, movetoworkspace, 5"
    "$mainMod SHIFT, 6, movetoworkspace, 6"
    "$mainMod SHIFT, 7, movetoworkspace, 7"
    "$mainMod SHIFT, 8, movetoworkspace, 8"
    "$mainMod SHIFT, 9, movetoworkspace, 9"

    # Move active window to workspace silently
    "$mainMod SHIFT ALT, 1, movetoworkspacesilent, 1"
    "$mainMod SHIFT ALT, 2, movetoworkspacesilent, 2"
    "$mainMod SHIFT ALT, 3, movetoworkspacesilent, 3"
    "$mainMod SHIFT ALT, 4, movetoworkspacesilent, 4"
    "$mainMod SHIFT ALT, 5, movetoworkspacesilent, 5"
    "$mainMod SHIFT ALT, 6, movetoworkspacesilent, 6"
    "$mainMod SHIFT ALT, 7, movetoworkspacesilent, 7"
    "$mainMod SHIFT ALT, 8, movetoworkspacesilent, 8"
    "$mainMod SHIFT ALT, 9, movetoworkspacesilent, 9"

    # Fast Workspace Navigation
    "$mainMod, Tab, workspace, e+1"
    "$mainMod SHIFT, Tab, workspace, e-1"
    "$mainMod CTRL, Tab, workspace, previous"
    "$mainMod, mouse_down, workspace, e+1"
    "$mainMod, mouse_up, workspace, e-1"

    # Screenshot & Utilities
    ", Print, exec, grim - | wl-copy"
    "$mainMod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
    "$mainMod, Print, exec, pkill hyprpicker || hyprpicker -a"
  ];

  bindl = [
    # Media & Hardware Keys (Locked / Non-repeating)
    ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPause, exec, playerctl play-pause"
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioPrev, exec, playerctl previous"
  ];

  bindel = [
    # Volume & Brightness (Repeating & Locked)
    ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
    ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
    ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
  ];

  bindm = [
    # Move/resize windows with mainMod + LMB/RMB and dragging
    "$mainMod, mouse:272, movewindow"
    "$mainMod, mouse:273, resizewindow"
  ];

  windowrule = [
    {
      name = "float-pavucontrol";
      "match:class" = "pavucontrol";
      float = true;
      center = true;
    }
    {
      name = "float-portal";
      "match:class" = "xdg-desktop-portal-gtk";
      float = true;
    }
    {
      name = "moneydance-popup-x";
      "match:class" = "^Moneydance";
      "match:title" = "^win";
      "match:float" = true;
      no_initial_focus = true;
    }
    {
      name = "moneydance-popup-wayland";
      "match:class" = "^Moneydance";
      "match:title" = "^$";
      "match:float" = true;
      no_initial_focus = true;
    }
  ];
}
