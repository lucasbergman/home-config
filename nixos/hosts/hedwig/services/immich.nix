{ config, ... }:
let
  mediaDirectory = "/storage/media/photos";
  externalHost = "photos.bergman.house";
in
{
  services.immich = {
    enable = true;
    host = "::1";
    mediaLocation = mediaDirectory;
  };

  # Immich serves its data from /storage
  systemd.services.immich-server.wants = [ "zfs.target" ];

  services.nginx.virtualHosts."${externalHost}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 5000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };

  # TODO: Ensure storage directories are set up
}
