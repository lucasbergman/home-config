{ lib, ... }:
let
  mkRates =
    {
      name,
      counter,
      aggregate ? lib.trivial.id,
    }:
    [
      {
        record = name;
        expr = aggregate counter;
      }
    ]
    ++
      builtins.map
        (rate: {
          record = "${name}:rate${rate}";
          expr = aggregate "rate(${counter}[${rate}])";
        })
        [
          "1m"
          "5m"
        ];
in
{
  groups = [
    {
      name = "unifi_controller";
      rules =
        builtins.map
          (var: {
            record = "unifi_controller:${var}";
            expr = "${var}{job='unifi_jvm'}";
          })
          [
            "jvm_memory_pool_bytes_used"
            "jvm_memory_bytes_used"
          ];
    }
    {
      name = "unifi";
      rules = builtins.concatLists [
        (mkRates {
          name = "unifi:wan:receive_bytes";
          counter = "unpoller_device_wan_receive_bytes_total{job='unifi'}";
        })
        (mkRates {
          name = "unifi:wan:transmit_bytes";
          counter = "unpoller_device_wan_transmit_bytes_total{job='unifi'}";
        })
        (mkRates {
          name = "unifi:device:receive_bytes";
          counter = "unpoller_device_receive_bytes_total{job='unifi'}";
        })
        (mkRates {
          name = "unifi:device:transmit_bytes";
          counter = "unpoller_device_transmit_bytes_total{job='unifi'}";
        })
      ];
    }
    {
      name = "node_net";
      rules = builtins.concatLists [
        (mkRates {
          name = "node:receive_bytes";
          counter = "node_network_receive_bytes_total{device=~'^(en|eth).*'}";
        })
        (mkRates {
          name = "node:transmit_bytes";
          counter = "node_network_transmit_bytes_total{device=~'^(en|eth).*'}";
        })
      ];
    }
    {
      name = "node_fs";
      rules = [
        {
          record = "node:filesystem_avail_bytes";
          expr = "node_filesystem_avail_bytes{job='node',fstype!~'(tmpfs|ramfs)'}";
        }
      ]
      ++ builtins.concatLists [
        (mkRates {
          name = "node:disk_read_seconds";
          counter = "node_disk_read_time_seconds_total";
        })
        (mkRates {
          name = "node:disk_write_seconds";
          counter = "node_disk_write_time_seconds_total";
        })
      ];
    }
    {
      name = "node_disk";
      rules = [
        {
          record = "node:disk:reallocated_sector_ct:raw";
          expr = "smartctl_device_attribute{attribute_id='5',attribute_value_type='raw'}";
        }
        {
          record = "node:disk:reported_uncorrect:raw";
          expr = "smartctl_device_attribute{attribute_id='187',attribute_value_type='raw'}";
        }
        {
          record = "node:disk:command_timeout:raw";
          expr = "smartctl_device_attribute{attribute_id='188',attribute_value_type='raw'} % 0x10000";
        }
        {
          record = "node:disk:current_pending_sector:raw";
          expr = "smartctl_device_attribute{attribute_id='197',attribute_value_type='raw'}";
        }
        {
          record = "node:disk:offline_uncorrectable:raw";
          expr = "smartctl_device_attribute{attribute_id='198',attribute_value_type='raw'}";
        }
        {
          alert = "node_disk_smart";
          expr = "delta({__name__=~'node:disk:[^:]+:raw'}[1h]) > 0";
          for = "1m";
          labels = {
            severity = "notify";
          };
          annotations = {
            summary = "Drive {{ $labels.device }} reports a SMART issue";
            description = "{{ $labels.__name__ }} has increased in the last hour for drive {{ $labels.device }}";
          };
        }
      ];
    }
    {
      name = "node_cpu";
      rules = mkRates {
        name = "node:cpu_seconds";
        counter = "node_cpu_seconds_total";
        aggregate = e: "sum(${e}) by (instance, mode)";
      };
    }
    {
      name = "weather";
      interval = "5m";
      rules = [
        {
          record = "weather:temperature_fahrenheit";
          expr = "label_replace(hass_sensor_unit_celsius{entity=~'sensor.weather_.*_temperature'}, 'station', '$1', 'entity', 'sensor.weather_(.+)_temperature') * 9 / 5 + 32";
        }
        {
          record = "weather:humidity_percent";
          expr = "label_replace(hass_sensor_unit_percent{entity=~'sensor.weather_.*_humidity'}, 'station', '$1', 'entity', 'sensor.weather_(.+)_humidity')";
        }
        {
          record = "weather:pressure_inhg";
          expr = "label_replace(hass_sensor_unit_inhg{entity=~'sensor.weather_.*_pressure'}, 'station', '$1', 'entity', 'sensor.weather_(.+)_pressure')";
        }
        {
          record = "weather:wind_speed_mph";
          expr = "label_replace(hass_sensor_unit_mph{entity=~'sensor.weather_.*_wind_speed'}, 'station', '$1', 'entity', 'sensor.weather_(.+)_wind_speed')";
        }
        {
          record = "weather:visibility_mi";
          expr = "label_replace(hass_sensor_unit_mi{entity=~'sensor.weather_.*_visibility'}, 'station', '$1', 'entity', 'sensor.weather_(.+)_visibility')";
        }
      ];
    }
    {
      name = "node_health";
      rules = [
        {
          record = "node:last_boot_time_seconds";
          expr = "node_boot_time_seconds";
        }
        {
          alert = "node_rebooted";
          expr = "changes(node_boot_time_seconds[1h]) > 0";
          for = "5m";
          labels = {
            severity = "notify";
          };
          annotations = {
            summary = "Node {{ $labels.instance }} has rebooted";
            description = "Node {{ $labels.instance }} rebooted at {{ $value | humanizeTimestamp }}";
          };
        }
      ];
    }
  ];
}
