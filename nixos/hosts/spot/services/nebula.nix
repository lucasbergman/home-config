let
  networkName = "bergnet";
  hostKeyPath = "/run/nebula-spot.key";
  hostKeySecretID = "projects/bergmans-services/secrets/nebula-host-key-spot/versions/1";
in
{
  ...
}:
{
  slb.security.secrets.nebula-spot-key = {
    before = [ "nebula@${networkName}.service" ];
    outPath = hostKeyPath;
    secretPath = hostKeySecretID;
    group = "nebula-${networkName}";
  };

  services.nebula.networks.${networkName} = {
    enable = true;
    isLighthouse = true;

    ca = ../../../common/global/nebula-bergnet-ca.crt;
    cert = ../nebula-bergnet-host.crt;
    key = hostKeyPath;

    lighthouse.dns = {
      enable = true;
      host = "10.7.1.1";
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
  };

  networking.firewall.trustedInterfaces = [ "nebula.${networkName}" ];
}
