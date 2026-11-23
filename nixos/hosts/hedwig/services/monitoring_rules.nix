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
          expr = aggregate "rate(${name}[${rate}])";
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
      # I caught WAN bytes metrics from unpoller running backward a few times per day
      # since I moved to the Cloud Gateway. The max_over_time(...[2m]) keeps them
      # non-decreasing, assuming things sort out in any given two-minute window.
      name = "unifi";
      rules = builtins.concatLists [
        (mkRates {
          name = "unifi:wan:receive_bytes";
          counter = "max_over_time(unpoller_device_wan_receive_bytes_total{job='unifi'}[2m])";
        })
        (mkRates {
          name = "unifi:wan:transmit_bytes";
          counter = "max_over_time(unpoller_device_wan_transmit_bytes_total{job='unifi'}[2m])";
        })
        (mkRates {
          name = "unifi:device:receive_bytes";
          counter = "max_over_time(unpoller_device_receive_bytes_total{job='unifi'}[2m])";
        })
        (mkRates {
          name = "unifi:device:transmit_bytes";
          counter = "max_over_time(unpoller_device_transmit_bytes_total{job='unifi'}[2m])";
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
      name = "purifier";
      interval = "1m";
      rules =
        let
          mkPurifierSensor =
            {
              record,
              metric,
              suffix,
              transform ? lib.trivial.id,
            }:
            {
              inherit record;
              expr = transform "label_replace(${metric}{entity=~'sensor\\\\..+_purifier_${suffix}'}, 'room', '$1', 'entity', 'sensor\\\\.(.+)_purifier_${suffix}')";
            };
          mkPurifierFan =
            {
              record,
              metric,
            }:
            {
              inherit record;
              expr = "label_replace(${metric}{entity=~'fan\\\\..+_purifier'}, 'room', '$1', 'entity', 'fan\\\\.(.+)_purifier')";
            };
        in
        [
          (mkPurifierSensor {
            record = "purifier:pm25_ugm3";
            metric = "hass_sensor_pm25_u0xb5g_per_mu0xb3";
            suffix = "pm2_5";
          })
          (mkPurifierSensor {
            record = "purifier:voc_ugm3";
            metric = "hass_sensor_volatile_organic_compounds_u0xb5g_per_mu0xb3";
            suffix = "volatile_organic_compounds";
          })
          (mkPurifierSensor {
            record = "purifier:co2_ppm";
            metric = "hass_sensor_carbon_dioxide_ppm";
            suffix = "carbon_dioxide";
          })
          (mkPurifierSensor {
            record = "purifier:etoh_ppm";
            metric = "hass_sensor_unit_ppm";
            suffix = "etoh";
          })
          (mkPurifierSensor {
            record = "purifier:filter_life_percent";
            metric = "hass_sensor_unit_percent";
            suffix = "filter_life";
          })
          (mkPurifierSensor {
            record = "purifier:temperature_fahrenheit";
            metric = "hass_sensor_temperature_celsius";
            suffix = "temperature";
            transform = e: "${e} * 9 / 5 + 32";
          })
          (mkPurifierSensor {
            record = "purifier:humidity_percent";
            metric = "hass_sensor_humidity_percent";
            suffix = "humidity";
          })
          (mkPurifierFan {
            record = "purifier:fan_on";
            metric = "hass_fan_state";
          })
          (mkPurifierFan {
            record = "purifier:fan_speed_percent";
            metric = "hass_fan_speed_percent";
          })
        ];
    }
    {
      name = "node_health";
      rules = [
        {
          record = "node:last_boot_time_seconds";
          expr = "node_boot_time_seconds";
        }
        # Using node_boot_time_seconds and ... preserves node_boot_time_seconds as
        # the metric value instead of the change count (usually 1.0). That way $value
        # in the annotation is the Unix timestamp of the boot time.
        {
          alert = "node_rebooted";
          expr = "node_boot_time_seconds and changes(node_boot_time_seconds[1h]) > 0";
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
    {
      name = "home_wan";
      rules = [
        {
          alert = "HomeIPAddressChanged";
          expr = "home_wan_dns_match == 0";
          labels = {
            severity = "mail";
          };
          annotations = {
            summary = "Home WAN IP changed to {{ $labels.wan_ip }}";
            description = "Home WAN IP is {{ $labels.wan_ip }}, but bergman.house resolves to {{ $labels.dns_ip }}";
          };
        }
      ];
    }
  ];
}
