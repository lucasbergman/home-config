{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.slb.nebula;
  networkName = "bergnet";
  lighthouseNebulaIP = "10.7.1.1";
  lighthouseExternalHost = "spot.bergmans.us";
  lighthouseExternalPort = 4242;
  # Cert and key are placed manually on each host
  certPath = "/etc/nebula-bergnet-host.crt";
  keyPath = "/etc/nebula-bergnet-host.key";
in
{
  options.slb.nebula = {
    enable = lib.mkEnableOption "Nebula bergnet configuration";

    isLighthouse = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this node is a lighthouse.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nebula.networks.${networkName} = {
      enable = true;
      isLighthouse = cfg.isLighthouse;

      ca = ../common/global/nebula-bergnet-ca.crt;
      cert = certPath;
      key = keyPath;

      lighthouses = lib.mkIf (!cfg.isLighthouse) [ lighthouseNebulaIP ];

      staticHostMap = lib.mkIf (!cfg.isLighthouse) {
        ${lighthouseNebulaIP} = [ "${lighthouseExternalHost}:${toString lighthouseExternalPort}" ];
      };

      lighthouse.dns = lib.mkIf cfg.isLighthouse {
        enable = true;
        host = lighthouseNebulaIP;
        port = 53;
      };

      firewall = {
        inbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];
        outbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];
      };

      settings = lib.mkIf (!cfg.isLighthouse) {
        punchy = {
          punch = true;
          respond = true;
        };
      };
    };

    networking.firewall.trustedInterfaces = [ "nebula.${networkName}" ];

    systemd.network.networks."nebula-${networkName}" = {
      matchConfig.Name = "nebula.${networkName}";
      dns = [ lighthouseNebulaIP ];
      networkConfig = {
        Domains = [ "~priv.bergman.house" ];
        KeepConfiguration = true;
        IPv6AcceptRA = false;
        LinkLocalAddressing = false;
      };
      linkConfig.RequiredForOnline = false;
      DHCP = "no";
    };
  };
}
