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

  registry = import ../common/global/nebula-bergnet-registry.nix;
  hostConfig = registry.hosts.${config.networking.hostName} or { };

  certPath = if cfg.useSecretManager then "/run/nebula/host.crt" else "/etc/nebula-bergnet-host.crt";
  keyPath = if cfg.useSecretManager then "/run/nebula/host.key" else "/etc/nebula-bergnet-host.key";
in
{
  options.slb.nebula = {
    enable = lib.mkEnableOption "Nebula bergnet configuration";

    ip = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = hostConfig.ip or null;
      description = "The IP address of this host on the Nebula mesh.";
    };

    isLighthouse = lib.mkOption {
      type = lib.types.bool;
      default = hostConfig.isLighthouse or false;
      description = "Whether this node is a lighthouse.";
    };

    useSecretManager = lib.mkOption {
      type = lib.types.bool;
      default = false; # TODO: enable by default
      description = "Whether to fetch Nebula certificates and keys from GCP Secret Manager.";
    };
  };

  config = lib.mkIf cfg.enable {
    slb.security.secrets = lib.mkIf cfg.useSecretManager {
      "nebula-cert" = {
        outPath = "/run/nebula/host.crt";
        secretPath = "projects/bergmans-services/secrets/nebula-cert-${config.networking.hostName}/versions/latest";
        restartUnits = [ "nebula-${networkName}.service" ];
      };
      "nebula-key" = {
        outPath = "/run/nebula/host.key";
        secretPath = "projects/bergmans-services/secrets/nebula-key-${config.networking.hostName}/versions/latest";
        restartUnits = [ "nebula-${networkName}.service" ];
      };
    };

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

    systemd.services."nebula-${networkName}" = lib.mkIf cfg.useSecretManager {
      after = [
        "secret-nebula-cert.service"
        "secret-nebula-key.service"
      ];
      wants = [
        "secret-nebula-cert.service"
        "secret-nebula-key.service"
      ];
      preStart = ''
        mkdir -p /run/nebula /var/lib/nebula
        if [ ! -s /run/nebula/host.crt ] && [ -s /var/lib/nebula/host.crt ]; then
          cp /var/lib/nebula/host.crt /run/nebula/host.crt
        fi
        if [ ! -s /run/nebula/host.key ] && [ -s /var/lib/nebula/host.key ]; then
          cp /var/lib/nebula/host.key /run/nebula/host.key
          chmod 0600 /run/nebula/host.key
        fi
        if [ -s /run/nebula/host.crt ]; then
          cp /run/nebula/host.crt /var/lib/nebula/host.crt
        fi
        if [ -s /run/nebula/host.key ]; then
          cp /run/nebula/host.key /var/lib/nebula/host.key
          chmod 0600 /var/lib/nebula/host.key
        fi
      '';
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
