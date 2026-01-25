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
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/bgp-data";
      readOnly = true;
      description = "Directory to store BGP data (managed by systemd StateDirectory)";
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
          tempOutFile = "${cfg.dataDir}/table.jsonl.tmp";
          outFile = "${cfg.dataDir}/table.jsonl";
          url = "https://bgp.tools/table.jsonl";

          tempAsnsFile = "${cfg.dataDir}/asns.csv.tmp";
          outAsnsFile = "${cfg.dataDir}/asns.csv";
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
