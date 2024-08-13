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

  systemd.services.idiotbox-pod = let
    name = "idiotbox";
    podScript = pkgs.writeShellScript "pod-${name}" ''
      podid=$(${pkgs.podman}/bin/podman pod create \
        -p 9091:9091 -p 51413:51413 \
        --name ${name} \
        --replace)
      sleep infinity
      ${pkgs.podman}/bin/podman pod rm $podid
    '';
  in {
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Restart = "on-failure";
      ExecStart = "${podScript}";
    };
  };

  virtualisation.oci-containers.containers.idiotbox-vpn = {
    image = "docker.io/qmcgaw/gluetun:v3.39";
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--privileged"
      "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      "--pod=idiotbox"
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

  # Make sure the VPN comes up after the pod exists, and take it down if the
  # pod is going away. N.B. containers have a `dependsOn` option, but that
  # doesn't work here; it assumes that all podman container services are
  # depending only on other containers.
  systemd.services.podman-idiotbox-vpn = {
    after = ["idiotbox-pod.service"];
    requires = ["idiotbox-pod.service"];
  };
}
