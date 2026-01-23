{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.slb.bgpData;
in
{
  options.slb.bgpData = {
    enable = lib.mkEnableOption "Daily BGP data fetcher";
    name = lib.mkOption {
      type = lib.types.str;
      description = "Contact name for bgp.tools User-Agent";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "Contact email for bgp.tools User-Agent";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.bgp-data = {
      description = "Fetch BGP table from bgp.tools";
      startAt = "daily";
      path = with pkgs; [ curl ];

      # Create /var/lib/bgp-data
      serviceConfig = {
        StateDirectory = "bgp-data";
        Type = "oneshot";
        User = "root";
        Group = "root";
      };

      script =
        let
          tempOutFile = "/var/lib/bgp-data/table.jsonl.tmp";
          outFile = "/var/lib/bgp-data/table.jsonl";
          url = "https://bgp.tools/table.jsonl";

          tempAsnsFile = "/var/lib/bgp-data/asns.csv.tmp";
          outAsnsFile = "/var/lib/bgp-data/asns.csv";
          urlAsns = "https://bgp.tools/asns.csv";
        in
        ''
          set -euo pipefail
          echo "Fetching ${url}..."
          curl --fail --silent \
            --user-agent "${cfg.name} - contact ${cfg.email}" \
            --output "${tempOutFile}" \
            "${url}"
          mv "${tempOutFile}" "${outFile}"
          chmod 644 "${outFile}"
          echo "Updated ${outFile}"

          echo "Fetching ${urlAsns}..."
          curl --fail --silent \
            --user-agent "${cfg.name} - contact ${cfg.email}" \
            --output "${tempAsnsFile}" \
            "${urlAsns}"
          mv "${tempAsnsFile}" "${outAsnsFile}"
          chmod 644 "${outAsnsFile}"
          echo "Updated ${outAsnsFile}"
        '';
    };
  };
}
