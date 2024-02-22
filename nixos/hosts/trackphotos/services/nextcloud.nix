{
  config,
  pkgs,
  ...
}: {
  services.nextcloud = {
    enable = true;
    hostName = "trackphotos.bergmans.us";
    https = true;
    package = pkgs.nextcloud28;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = "/run/nextcloud-admin-pass";
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };
}
