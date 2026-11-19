{
  config,
  pkgs,
  lib,
  mypkgs,
  ...
}:
let
  cfg = config.slb.asnBlocking;
  bgpTable = "${config.slb.bgpData.dataDir}/table.jsonl";
  asnsFile = pkgs.writeText "asn-blocklist.txt" (lib.concatStringsSep "\n" cfg.asns);
in
{
  options.slb.asnBlocking = {
    enable = lib.mkEnableOption "ASN blocking via nftables";
    asns = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "^AS[0-9]+$");
      default = [ ];
      description = "List of ASNs to block (e.g., 'AS12345')";
    };
    tableName = lib.mkOption {
      type = lib.types.str;
      default = "slb-asn-blocking";
      description = "Name of the nftables table for blocked ASNs";
      readOnly = true;
    };
    setName = lib.mkOption {
      type = lib.types.str;
      default = "blocked-ranges";
      description = "Name of the nftables set for blocked address ranges";
    };
  };

  config = lib.mkIf cfg.enable {
    slb.bgpData.enable = true;
    networking.nftables.enable = true;

    networking.nftables.tables."${cfg.tableName}" = {
      family = "inet";
      content = ''
        set ${cfg.setName} {
          type ipv4_addr
          flags interval
        }

        chain input {
          type filter hook input priority -10; policy accept;
          ip saddr @${cfg.setName} counter drop comment "asn-blocking"
        }
      '';
    };

    systemd.services.nftables.serviceConfig.ExecReload = lib.mkAfter [
      "+${config.systemd.package}/bin/systemctl start --no-block update-asn-blocklist.service"
    ];

    systemd.services.asn-blocklist = {
      description = "Ensure ASN blocklist is applied to nftables";
      wantedBy = [ "multi-user.target" ];
      after = [ "nftables.service" ];
      requires = [ "nftables.service" ];
      partOf = [ "nftables.service" ];
      restartTriggers = [ asnsFile ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.systemd.package}/bin/systemctl start update-asn-blocklist.service";
      };
    };

    systemd.paths.update-asn-blocklist = {
      description = "Watch BGP table for updates to refresh ASN blocklist";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = bgpTable;
    };

    systemd.services.update-asn-blocklist = {
      description = "Update ASN blocklist from local BGP data";
      after = [
        "nftables.service"
        "bgp-data.service"
      ];
      requires = [ "nftables.service" ];
      path = with pkgs; [
        coreutils
        nftables
        mypkgs.asn-blocklist-gen
        config.systemd.package
      ];
      script = ''
        set -euo pipefail

        if [ ! -s "${bgpTable}" ]; then
          echo "BGP table ${bgpTable} missing; fetching via bgp-data.service..."
          systemctl start bgp-data.service
        fi

        NFT_FILE=$(mktemp)
        trap 'rm -f "$NFT_FILE"' EXIT

        asn-blocklist-gen \
          --set-name "${cfg.setName}" \
          --table "${cfg.tableName}" \
          --family "inet" \
          --bgp-table "${bgpTable}" \
          "${asnsFile}" > "$NFT_FILE"

        if [ ! -s "$NFT_FILE" ]; then
          echo "No blocklist generated"
          exit 0
        fi

        nft -f "$NFT_FILE"
        echo "Blocklist updated"
      '';
      serviceConfig = {
        Type = "oneshot";
        PrivateTmp = true;
        ProtectSystem = "strict";
      };
    };
  };
}
