{ config, ... }:
let
  mediaDirectory = "/storage/media/photos";
  externalHost = "photos.bergman.house";
  # TODO: Don't expose on the LAN
  serverHostAddr = "192.168.101.3";
in
{
  services.immich = {
    enable = true;
    host = serverHostAddr;
    mediaLocation = mediaDirectory;
  };

  # Immich serves its data from /storage
  systemd.services.immich-server.wants = [ "zfs.target" ];

  services.nginx.virtualHosts."${externalHost}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${serverHostAddr}:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 10000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };

  # TODO: Ensure storage directories are set up
}
