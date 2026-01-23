{
  config,
  lib,
  pkgs,
  mypkgs,
  ...
}:
let
  cfg = config.slb.ipAbuseReport;
in
{
  options.slb.ipAbuseReport = {
    enable = lib.mkEnableOption "Abuse reporting tool";
    reportEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email address to send daily abuse reports to";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ mypkgs.ip-abuse-report ];

    # Ensure data service is enabled if this tool is used
    slb.bgpData.enable = true;

    systemd.services.abuse-report-daily = {
      description = "Generate and email daily abuse report";
      path = with pkgs; [
        coreutils
        gnugrep
        gnused
        systemd
        mypkgs.ip-abuse-report
        postfix
      ];
      script = ''
        set -euo pipefail
        IPS_FILE=$(mktemp)
        REPORT_FILE=$(mktemp)

        # Cleanup trap
        trap 'rm -f "$IPS_FILE" "$REPORT_FILE"' EXIT

        # Extract IPs from yesterday's Postfix logs
        journalctl --unit postfix.service --since yesterday --until today | \
          grep 'SASL LOGIN authentication failed' | \
          cut -d '[' -f3 | cut -d ']' -f1 >> "$IPS_FILE"

        # Extract IPs from yesterday's SSH logs
        journalctl --unit sshd.service --since yesterday --until today | \
          grep ': Invalid user' | \
          sed 's,^.*from \([^ ]*\) .*$,\1,' >> "$IPS_FILE"

        if [ ! -s "$IPS_FILE" ]; then
          echo "No abusive IPs found for yesterday."
          exit 0
        fi

        # Generate report
        ip-abuse-report < "$IPS_FILE" > "$REPORT_FILE"

        # Check if report has content
        LINE_COUNT=$(wc -l < "$REPORT_FILE")
        if [ "$LINE_COUNT" -le 0 ]; then
            echo "Report empty (no ASNs met threshold)."
            exit 0
        fi

        (
          echo "To: ${cfg.reportEmail}"
          echo "From: ${cfg.reportEmail}"
          echo "Subject: ASN Abuse Report: ${config.networking.hostName} ($(date -d yesterday +%Y-%m-%d))"
          echo "Content-Type: text/html; charset=utf-8"
          echo ""
          echo "<html>"
          echo "<body>"
          echo "<p>Daily ASN Abuse Report for <b>${config.networking.hostName}</b></p>"
          echo "<p>Date: $(date -d yesterday +%Y-%m-%d)</p>"
          echo "<pre>"
          cat "$REPORT_FILE"
          echo "</pre>"
          echo "</body>"
          echo "</html>"
        ) | sendmail -f ${cfg.reportEmail} -t
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

    systemd.timers.abuse-report-daily = {
      description = "Timer for daily abuse report";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
