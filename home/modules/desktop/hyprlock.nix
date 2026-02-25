{ config, lib, ... }:

{
  config = lib.mkIf config.slb.isDesktop {
    programs.hyprlock = {
      enable = true;
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
            color = "rgba(20, 20, 20, 1.0)";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            size = "400, 60";
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.35;
            dots_center = true;
            outer_color = "rgba(200, 200, 200, 1.0)";
            inner_color = "rgba(30, 30, 30, 0.8)";
            font_color = "rgba(200, 200, 200, 1.0)";
            fade_on_empty = false;
            placeholder_text = "Enter Password";
            hide_input = false;
            position = "0, -20";
            halign = "center";
            valign = "center";
            rounding = 0;
          }
        ];

        label = [
          {
            text = "$TIME";
            color = "rgba(200, 200, 200, 1.0)";
            font_size = 96;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 150";
            halign = "center";
            valign = "center";
          }
          {
            text = "cmd[perspective] date +'%A, %B %d'";
            color = "rgba(200, 200, 200, 0.8)";
            font_size = 24;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 80";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
