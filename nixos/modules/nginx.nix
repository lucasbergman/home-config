{ config, lib, ... }:
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
