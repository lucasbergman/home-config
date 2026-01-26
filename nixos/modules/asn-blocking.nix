{
  config,
  pkgs,
  lib,
  mypkgs,
  ...
}:
let
  cfg = config.slb.asnBlocking;
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
          ip saddr @${cfg.setName} drop
        }
      '';
    };

    systemd.services.update-asn-blocklist = {
      description = "Update ASN blocklist from local BGP data";
      after = [ "bgp-data.service" ];
      wants = [ "bgp-data.service" ];
      path = with pkgs; [
        coreutils
        nftables
        mypkgs.asn-blocklist-gen
      ];
      script = ''
        set -euo pipefail

        NFT_FILE=$(mktemp)
        trap 'rm -f "$NFT_FILE"' EXIT

        asn-blocklist-gen \
          --set-name "${cfg.setName}" \
          --table "${cfg.tableName}" \
          --family "inet" \
          --bgp-table "${config.slb.bgpData.dataDir}/table.jsonl" > "$NFT_FILE" <<EOF
        ${lib.concatStringsSep "\n" cfg.asns}
        EOF

        if [ ! -s "$NFT_FILE" ]; then
          echo "No blocklist generated"
          exit 0
        fi

        nft -f "$NFT_FILE"
        echo "Blocklist updated"
      '';
      startAt = "daily";
      serviceConfig = {
        Type = "oneshot";
        PrivateTmp = true;
        ProtectSystem = "strict";
      };
    };
  };
}
