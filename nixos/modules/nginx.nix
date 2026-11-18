{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    slb.nginx = {
      enable = lib.mkOption {
        description = "Whether to enable nginx and its typical setup";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config =
    let
      cfg = config.slb.nginx;
    in
    lib.mkIf cfg.enable {
      services.nginx = {
        enable = true;
        # Temporary security override until nixos-26.05 picks up nixpkgs PR #589970
        # (CVE-2026-123007, CVE-2026-118899, CVE-2026-113425, CVE-2026-123634, etc.)
        package = pkgs.nginxStable.overrideAttrs (rec {
          version = "1.30.7";
          nginxVersion = version;
          src = pkgs.fetchurl {
            url = "https://nginx.org/download/nginx-${version}.tar.gz";
            hash = "sha256-JWW1yDcFDpWPcPsPc8SOK8pFQq00n9NW9G+wxyYQvG4=";
          };
        });
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
