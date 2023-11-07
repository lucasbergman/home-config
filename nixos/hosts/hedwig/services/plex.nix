{nixpkgs-unstable, ...}: {
  services.plex = {
    enable = false;
    package = nixpkgs-unstable.plex;
    # TODO: Set dataDir to a better place
  };

  # TODO: After hedwig is exposed to the Internet, we can remove this (and the
  # acme/nginx group hack) and just use enableACME in the nginx module
  security.acme.certs."plex.bergman.house" = {};

  services.nginx.virtualHosts."plex.bergman.house" = {
    forceSSL = true;
    useACMEHost = "plex.bergman.house";

    extraConfig = ''
      # https://blog.cloudflare.com/ocsp-stapling-how-cloudflare-just-made-ssl-30/
      ssl_stapling on;
      ssl_stapling_verify on;

      # Plex header fields
      proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
      proxy_set_header X-Plex-Device $http_x_plex_device;
      proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
      proxy_set_header X-Plex-Platform $http_x_plex_platform;
      proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
      proxy_set_header X-Plex-Product $http_x_plex_product;
      proxy_set_header X-Plex-Token $http_x_plex_token;
      proxy_set_header X-Plex-Version $http_x_plex_version;
      proxy_set_header X-Plex-Nocache $http_x_plex_nocache;
      proxy_set_header X-Plex-Provides $http_x_plex_provides;
      proxy_set_header X-Plex-Device-Vendor $http_x_plex_device_vendor;
      proxy_set_header X-Plex-Model $http_x_plex_model;

      # Buffering off send to the client as soon as the data is received from Plex.
      proxy_redirect off;
      proxy_buffering off;
    '';

    locations."/" = {
      proxyPass = "http://[::1]:32400/";
      proxyWebsockets = true;
    };
  };
}
