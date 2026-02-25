{ config, lib, ... }:

{
  config = lib.mkIf config.slb.isDesktop {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 300; # 5 min
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 600; # 10 min
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };
  };
}
