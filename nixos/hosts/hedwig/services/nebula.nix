let
  networkName = "bergnet";
  hostKeyPath = "/run/nebula-hedwig.key";
  hostKeySecretID = "projects/bergmans-services/secrets/nebula-host-key-hedwig/versions/1";
  lighthouseNebulaIP = "10.7.1.1";
in
{
  ...
}:
{
  slb.security.secrets.nebula-hedwig-key = {
    before = [ "nebula@${networkName}.service" ];
    outPath = hostKeyPath;
    secretPath = hostKeySecretID;
    group = "nebula-${networkName}";
  };

  services.nebula.networks.${networkName} = {
    enable = true;

    ca = ../../../common/global/nebula-bergnet-ca.crt;
    cert = ../nebula-bergnet-host.crt;
    key = hostKeyPath;

    lighthouses = [ lighthouseNebulaIP ];
    staticHostMap = {
      ${lighthouseNebulaIP} = [ "spot.bergmans.us:4242" ];
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

    settings = {
      punchy = {
        punch = true;
        respond = true;
      };
    };
  };

  networking.firewall.trustedInterfaces = [ "nebula.${networkName}" ];
}
