let
  mkRates =
    counter:
    builtins.map
      (rate: {
        record = "${counter}:rate${rate}";
        expr = "rate(${counter}[${rate}])";
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
      rules =
        [
          {
            record = "unifi:wan:receive_bytes";
            expr = "unpoller_device_wan_receive_bytes_total{job='unifi'}";
          }
          {
            record = "unifi:wan:transmit_bytes";
            expr = "unpoller_device_wan_transmit_bytes_total{job='unifi'}";
          }
          {
            record = "unifi:device:receive_bytes";
            expr = "unpoller_device_receive_bytes_total{job='unifi'}";
          }
          {
            record = "unifi:device:transmit_bytes";
            expr = "unpoller_device_transmit_bytes_total{job='unifi'}";
          }
        ]
        ++ (mkRates "unifi:wan:receive_bytes")
        ++ (mkRates "unifi:wan:transmit_bytes")
        ++ (mkRates "unifi:device:receive_bytes")
        ++ (mkRates "unifi:device:transmit_bytes");
    }
    {
      name = "node_net";
      rules =
        [
          {
            record = "node:receive_bytes";
            expr = "node_network_receive_bytes_total{device=~'^(en|eth).*'}";
          }
          {
            record = "node:transmit_bytes";
            expr = "node_network_transmit_bytes_total{device=~'^(en|eth).*'}";
          }
        ]
        ++ (mkRates "node:receive_bytes")
        ++ (mkRates "node:transmit_bytes");
    }
    {
      name = "node_fs";
      rules =
        [
          {
            record = "node:filesystem_avail_bytes";
            expr = "node_filesystem_avail_bytes{job='node',fstype!~'(tmpfs|ramfs)'}";
          }
          {
            record = "node:disk_read_seconds";
            expr = "node_disk_read_time_seconds_total";
          }
          {
            record = "node:disk_write_seconds";
            expr = "node_disk_write_time_seconds_total";
          }
        ]
        ++ (mkRates "node:disk_read_seconds")
        ++ (mkRates "node:disk_write_seconds");
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
          expr = "smartctl_device_attribute{attribute_id='188',attribute_value_type='raw'}";
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
          expr = "{__name__=~'node:disk:[^:]+:raw'} > 0";
          for = "1m";
          labels = {
            severity = "notify";
          };
          annotations = {
            summary = "Drive {{ $labels.device }} reports a SMART issue";
            description = "{{ $labels.__name__ }} is {{ $value }} for drive {{ $labels.device }}";
          };
        }
      ];
    }
    {
      name = "node_cpu";
      rules = [
        {
          record = "node:cpu_seconds";
          expr = "sum(node_cpu_seconds_total) by (instance, mode)";
        }
      ] ++ (mkRates "node:cpu_seconds");
    }
  ];
}
