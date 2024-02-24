{
  config,
  pkgs,
  ...
}: let
  rootPasswordPath = "/run/nextcloud-admin-pass";
in {
  slb.security.secrets."nextcloud-root-password" = let
    template =
      pkgs.writeText
      "nextcloud-password.tmpl"
      "{{gcpSecret \"projects/bergmans-services/secrets/trackphotos-root-password/versions/1\" }}";
  in {
    inherit template;
    outPath = rootPasswordPath;
    before = ["nextcloud-setup.service"];
    owner = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    hostName = "trackphotos.bergmans.us";
    https = true;
    package = pkgs.nextcloud28;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = rootPasswordPath;
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };
}
