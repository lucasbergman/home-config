{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.slb.isDesktop {
    programs.hyprlock = {
      enable = true;
      package = pkgs.hyprlock.overrideAttrs (oldAttrs: {
        dontStrip = true;
        cmakeBuildType = "Debug";
      });
      settings = {
        general = {
          disable_loading = true;
          grace = 0;
          hide_cursor = true;
          no_fade_in = false;
          ignore_empty_input = true;
        };

        background = [
          {
            path = "screenshot";
            color = "rgba(26, 27, 38, 1.0)";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            size = "340, 50";
            outline_thickness = 2;
            dots_size = 0.25;
            dots_spacing = 0.3;
            dots_center = true;
            outer_color = "rgba(122, 162, 247, 0.8)";
            inner_color = "rgba(26, 27, 38, 0.85)";
            font_color = "rgba(192, 202, 245, 1.0)";
            check_color = "rgba(158, 206, 106, 1.0)";
            fail_color = "rgba(247, 118, 142, 1.0)";
            fade_on_empty = false;
            placeholder_text = "󰌾  Enter Password...";
            hide_input = false;
            position = "0, -30";
            halign = "center";
            valign = "center";
            rounding = 12;
          }
        ];

        label = [
          {
            text = "$TIME";
            color = "rgba(192, 202, 245, 1.0)";
            font_size = 84;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 140";
            halign = "center";
            valign = "center";
          }
          {
            text = "cmd[perspective] date +'%A, %B %d'";
            color = "rgba(122, 162, 247, 0.9)";
            font_size = 20;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 75";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
