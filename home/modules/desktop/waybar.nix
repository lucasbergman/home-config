{
  config,
  lib,
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
          height = 32;
          spacing = 6;
          margin-top = 6;
          margin-left = 8;
          margin-right = 8;
          modules-left = [
            "custom/logo"
            "hyprland/workspaces"
            "hyprland/window"
          ];
          modules-center = [
            "idle_inhibitor"
            "clock"
          ];
          modules-right = [
            "group/tray-expander"
            "pulseaudio"
            "bluetooth"
            "network"
            "cpu"
            "memory"
            "battery"
          ];

          "custom/logo" = {
            format = ""; # nf-linux-nixos
            tooltip = false;
            on-click = "wofi --show run";
          };

          "hyprland/workspaces" = {
            on-click = "activate";
            format = "{icon}";
            format-icons = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "urgent" = "󱓻"; # nf-md-circle_double
              "active" = "󱓻"; # nf-md-circle_double
              "default" = ""; # nf-cod-circle_filled
            };
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
            };
          };

          "hyprland/window" = {
            format = "{title}";
            max-length = 40;
            separate-outputs = true;
          };

          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = ""; # nf-fa-eye
              deactivated = ""; # nf-fa-eye_slash
            };
            tooltip-format-activated = "Idle Inhibitor: Active";
            tooltip-format-deactivated = "Idle Inhibitor: Inactive";
          };

          "clock" = {
            format = "{:L%A %H:%M}";
            format-alt = "{:L%Y-%m-%d %H:%M:%S}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "month";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#ff7a93'><b>{}</b></span>";
                days = "<span color='#c0caf5'><b>{}</b></span>";
                weeks = "<span color='#7aa2f7'><b>W{}</b></span>";
                weekdays = "<span color='#e0af68'><b>{}</b></span>";
                today = "<span color='#7aa2f7'><b><u>{}</u></b></span>";
              };
            };
          };

          "group/tray-expander" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 400;
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

          "tray" = {
            icon-size = 15;
            spacing = 8;
          };

          "pulseaudio" = {
            format = "{icon} {volume}%";
            format-muted = "  Muted"; # nf-md-volume_off
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
            scroll-step = 2;
            on-click = "pavucontrol";
            on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            tooltip-format = "{desc}: {volume}%";
          };

          "bluetooth" = {
            format = " {status}"; # nf-fa-bluetooth
            format-connected = "󰂱 {device_alias}"; # nf-md-bluetooth_connect
            format-connected-battery = "󰂱 {device_alias} ({device_battery_percentage}%)"; # nf-md-bluetooth_connect
            format-disabled = "󰂲 Off"; # nf-md-bluetooth_off
            tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t({device_battery_percentage}%)";
          };

          "network" = {
            format-wifi = "{icon} {essid}";
            format-ethernet = "󰀂 Wired"; # nf-md-ethernet
            format-disconnected = "󰤮 Offline"; # nf-md-wifi_off
            format-icons = [
              "󰤯" # nf-md-wifi_strength_outline
              "󰤟" # nf-md-wifi_strength_1
              "󰤢" # nf-md-wifi_strength_2
              "󰤥" # nf-md-wifi_strength_3
              "󰤨" # nf-md-wifi_strength_4
            ];
            tooltip-format-wifi = "{essid} ({signalStrength}%)\nIP: {ipaddr}\nGateway: {gwaddr}";
            tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
            tooltip-format-disconnected = "Disconnected";
          };

          "cpu" = {
            interval = 4;
            format = "󰍛 {usage}%"; # nf-md-cpu_64_bit
            tooltip = true;
          };

          "memory" = {
            interval = 5;
            format = "󰘚 {percentage}%"; # nf-md-memory
            tooltip-format = "RAM: {used:0.1f}GiB / {total:0.1f}GiB ({percentage}%)\nSwap: {swapUsed:0.1f}GiB / {swapTotal:0.1f}GiB";
          };

          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%"; # nf-md-battery_charging
            format-plugged = " {capacity}%"; # nf-fa-plug
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
            tooltip-format = "{timeTo}\nPower: {power:0.1f}W";
          };
        };
      };
      style = builtins.readFile ./waybar.css;
    };
  };
}
