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
        jq
        systemd
        mypkgs.ip-abuse-report
        postfix
      ];
      script = ''
        set -euo pipefail
        REPORT_FILE=$(mktemp)

        # Cleanup trap
        trap 'rm -f "$REPORT_FILE"' EXIT

        # Extract abuse attempts from yesterday's logs and generate report
        (
          # Postfix SASL authentication failures
          journalctl --output json --unit postfix.service --since yesterday --until today | \
            jq -c 'select(.MESSAGE | test("SASL LOGIN authentication failed")) |
                   {ip: (.MESSAGE | match("\\[([^\\]]+)\\]").captures[0].string),
                    time_unix_us: ._SOURCE_REALTIME_TIMESTAMP,
                    line: .MESSAGE}'

          # SSH invalid user attempts
          journalctl --output json --unit sshd.service --since yesterday --until today | \
            jq -c 'select(.MESSAGE | test("^Invalid user ")) |
                   {ip: (.MESSAGE | match("from ([^ ]+)").captures[0].string),
                    time_unix_us: ._SOURCE_REALTIME_TIMESTAMP,
                    line: .MESSAGE}'
        ) | \
          add-asn-info \
            --bgp-table "${config.slb.bgpData.dataDir}/table.jsonl" \
            --asn-table "${config.slb.bgpData.dataDir}/asns.csv" | \
          ip-abuse-report > "$REPORT_FILE"

        if [ ! -s "$REPORT_FILE" ]; then
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
