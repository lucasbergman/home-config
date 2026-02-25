{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.slb.isDesktop {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 28;
          spacing = 0;
          modules-left = [
            "custom/logo"
            "hyprland/workspaces"
          ];
          modules-center = [
            "idle_inhibitor"
            "clock"
          ];
          modules-right = [
            "group/tray-expander"
            "bluetooth"
            "network"
            "pulseaudio"
            "cpu"
            "battery"
          ];

          "group/tray-expander" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 600;
              children-class = "tray-group-item";
            };
            modules = [
              "custom/expand-icon"
              "tray"
            ];
          };

          "custom/expand-icon" = {
            format = ""; # nf-fa-angle_left
            tooltip = false;
          };

          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = ""; # nf-fa-eye
              deactivated = ""; # nf-fa-eye_slash
            };
          };

          "custom/logo" = {
            format = ""; # nf-linux-nixos
            tooltip = false;
            on-click = "wofi --show run";
          };

          "hyprland/workspaces" = {
            on-click = "activate";
            format = "{icon}";
            format-icons = {
              "default" = ""; # nf-cod-circle_filled
              "active" = "󱓻"; # nf-md-circle_double
              "urgent" = "󱓻"; # nf-md-circle_double
            };
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
            };
          };

          "clock" = {
            format = "{:L%A %H:%M}";
            format-alt = "{:L%Y-%m-%d %H:%M:%S}";
            tooltip = false;
          };

          "cpu" = {
            interval = 5;
            format = "󰍛"; # nf-md-cpu_64_bit
            tooltip = true;
          };

          "network" = {
            format-wifi = "{icon}";
            format-ethernet = "󰀂"; # nf-md-ethernet
            format-disconnected = "󰤮"; # nf-md-wifi_off
            format-icons = [
              "󰤯" # nf-md-wifi_strength_outline
              "󰤟" # nf-md-wifi_strength_1
              "󰤢" # nf-md-wifi_strength_2
              "󰤥" # nf-md-wifi_strength_3
              "󰤨" # nf-md-wifi_strength_4
            ];
            tooltip-format-wifi = "{essid} ({signalStrength}%)";
            tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
            tooltip-format-disconnected = "Disconnected";
          };

          "bluetooth" = {
            format = ""; # nf-fa-bluetooth
            format-connected = "󰂱"; # nf-md-bluetooth_connect
            format-disabled = "󰂲"; # nf-md-bluetooth_off
            tooltip-format = "{num_connections} connected";
          };

          "pulseaudio" = {
            format = "{icon}";
            format-muted = ""; # nf-md-volume_off
            format-icons = {
              headphone = ""; # nf-fa-headphones
              hands-free = ""; # nf-fa-headset
              headset = ""; # nf-fa-headset
              phone = ""; # nf-fa-phone
              portable = ""; # nf-fa-phone
              car = ""; # nf-fa-car
              default = [
                "" # nf-fa-volume_off
                "" # nf-fa-volume_down
                "" # nf-fa-volume_up
              ];
            };
            on-click = "pavucontrol";
          };

          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% 󰂄"; # nf-md-battery_charging
            format-plugged = "{capacity}% "; # nf-fa-plug
            format-icons = [
              "󰁺" # nf-md-battery_10
              "󰁻" # nf-md-battery_20
              "󰁼" # nf-md-battery_30
              "󰁽" # nf-md-battery_40
              "󰁾" # nf-md-battery_50
              "󰁿" # nf-md-battery_60
              "󰂀" # nf-md-battery_70
              "󰂁" # nf-md-battery_80
              "󰂂" # nf-md-battery_90
              "󰁹" # nf-md-battery
            ];
          };

          "tray" = {
            icon-size = 14;
            spacing = 10;
          };
        };
      };
      style = builtins.readFile ./waybar.css;
    };
  };
}
