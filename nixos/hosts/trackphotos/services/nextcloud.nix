{
  config,
  pkgs,
  ...
}: {
  slb.security.secrets = {
    "nextcloud-root-password" = let
      template =
        pkgs.writeText
        "nextcloud-password.tmpl"
        "{{gcpSecret \"projects/bergmans-services/secrets/trackphotos-root-password/versions/1\" }}";
    in {
      inherit template;
      outPath = "/run/nextcloud-admin-pass";
      before = ["nextcloud-setup.service"];
      owner = "nextcloud";
    };

    "spaces-secret" = let
      template =
        pkgs.writeText
        "spaces-secret.tmpl"
        "{{gcpSecret \"projects/bergmans-services/secrets/trackphotos-storage-secret/versions/1\" }}";
    in {
      inherit template;
      outPath = "/run/spaces-secret";
      before = ["nextcloud-setup.service"];
      owner = "nextcloud";
    };
  };

  services.nextcloud = {
    enable = true;
    hostName = "trackphotos.bergmans.us";
    https = true;
    package = pkgs.nextcloud28;
    database.createLocally = true;
    logLevel = 0;
    config = {
      dbtype = "pgsql";
      adminpassFile = config.slb.security.secrets."nextcloud-root-password".outPath;
      defaultPhoneRegion = "US";
      objectstore.s3 = {
        enable = true;
        autocreate = true;
        bucket = "trackphotos";
        hostname = "nyc3.digitaloceanspaces.com";
        region = "nyc3";
        key = "DO00QEXQY7XNM68YHJXV";
        secretFile = config.slb.security.secrets."spaces-secret".outPath;
      };
    };
    extraOptions = {
      mail_smtphost = "email-smtp.us-east-2.amazonaws.com";
      mail_smtpport = 587;
      mail_smtpauth = true;
    };
    secretFile = null;
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };
}
