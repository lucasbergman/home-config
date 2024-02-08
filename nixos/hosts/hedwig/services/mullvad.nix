{
  config,
  pkgs,
  ...
}: let
  mullvadSecretsEnvFile = "/run/mullvad-secrets.env";
in {
  slb.security.secrets."mullvad" = {
    before = ["podman-idiotbox-vpn.service"];
    outPath = mullvadSecretsEnvFile;
    template = pkgs.writeText "mullvad-secrets.env" ''
      MULLVAD_ACCOUNT={{gcpSecret "projects/bergmans-services/secrets/mullvad-account/versions/1"}}
      WIREGUARD_PRIVATE_KEY={{gcpSecret "projects/bergmans-services/secrets/mullvad-wg-key-hedwig/versions/1"}}
    '';
  };

  virtualisation.oci-containers.containers.idiotbox-vpn = {
    image = "docker.io/qmcgaw/gluetun:v3.37";
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--privileged"
      "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      "--pod=new:idiotbox"
    ];

    ports = [
      "9091:9091"
      "51413:51413"
    ];

    # TODO: Make sure state directory exists
    volumes = ["/var/lib/gluetun:/gluetun"];

    # TODO: Get local IPv4 address from the API
    environment = {
      DOT = "off";
      DNS_ADDRESS = "10.64.0.1";
      VPN_SERVICE_PROVIDER = "mullvad";
      VPN_TYPE = "wireguard";
      FIREWALL_DEBUG = "on";
      FIREWALL_OUTBOUND_SUBNETS = "192.168.101.0/24";
      WIREGUARD_ADDRESSES = "10.69.172.88/32";
      SERVER_CITIES = "Chicago IL";
      PUID = builtins.toString config.users.users.idiotbox.uid;
      PGID = builtins.toString config.users.groups.idiotbox.gid;
    };

    environmentFiles = [mullvadSecretsEnvFile];
  };
}
