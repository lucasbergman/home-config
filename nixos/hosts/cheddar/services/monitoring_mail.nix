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
          "5m"
          "15m"
          "1h"
        ];

  mkGauge =
    { name, expr }:
    [
      {
        record = name;
        inherit expr;
      }
    ];
in
{
  groups = [
    {
      name = "postfix";
      rules = builtins.concatLists [
        # Queue depths (gauges)
        (mkGauge {
          name = "postfix:queue:deferred";
          expr = ''postfix_showq_queue_depth{queue="deferred"}'';
        })
        (mkGauge {
          name = "postfix:queue:active";
          expr = ''postfix_showq_queue_depth{queue="active"}'';
        })

        # Message send rates by status
        (mkRates {
          name = "postfix:smtp:sent";
          counter = ''postfix_smtp_messages_processed_total{status="sent"}'';
        })
        (mkRates {
          name = "postfix:smtp:bounced";
          counter = ''postfix_smtp_messages_processed_total{status="bounced"}'';
        })
        (mkRates {
          name = "postfix:smtp:deferred";
          counter = ''postfix_smtp_messages_processed_total{status="deferred"}'';
        })

        # Bounces by DSN code (e.g. auth failures are 5.7.x)
        (mkRates {
          name = "postfix:bounced_by_dsn";
          counter = "postfix_smtp_bounced_messages_by_dsn_total";
        })

        # Outbound connection issues
        (mkRates {
          name = "postfix:smtp:connection_timeout";
          counter = "postfix_smtp_connection_timed_out_total";
        })

        # Inbound connections and rejections
        (mkRates {
          name = "postfix:smtpd:connects";
          counter = "postfix_smtpd_connects_total";
        })
        (mkRates {
          name = "postfix:smtpd:rejected";
          counter = "postfix_smtpd_messages_rejected_total";
          aggregate = e: "sum(${e}) by (instance)";
        })
        (mkRates {
          name = "postfix:smtpd:sasl_failures";
          counter = "postfix_smtpd_sasl_authentication_failures_total";
        })

        # Alerts
        [
          {
            alert = "postfix_deferred_queue_growing";
            expr = ''postfix:queue:deferred > 10'';
            for = "30m";
            labels.severity = "warning";
            annotations = {
              summary = "Postfix deferred queue is growing";
              description = "{{ $value }} messages in deferred queue for >30 minutes";
            };
          }
          {
            alert = "postfix_high_bounce_rate";
            expr = ''
              postfix:smtp:bounced:rate15m
                / (postfix:smtp:sent:rate15m + postfix:smtp:bounced:rate15m + 0.001)
                > 0.1
            '';
            for = "30m";
            labels.severity = "warning";
            annotations = {
              summary = "Postfix bounce rate is high";
              description = "Bounce rate is {{ $value | humanizePercentage }} for >30 minutes";
            };
          }
          {
            alert = "postfix_sasl_brute_force";
            expr = ''postfix:smtpd:sasl_failures:rate15m > 1'';
            for = "10m";
            labels.severity = "notify";
            annotations = {
              summary = "Possible SASL brute force attack";
              description = "{{ $value | humanize }} auth failures/sec over 15 minutes";
            };
          }
        ]
      ];
    }
  ];
}
