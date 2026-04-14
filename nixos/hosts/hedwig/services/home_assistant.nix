{ pkgs, ... }:
{
  slb.security.secrets."home-assistant-secrets" = {
    before = [ "home-assistant.service" ];
    outPath = "/var/lib/hass/secrets.yaml";
    owner = "hass";
    secretPath = "projects/bergmans-services/secrets/home-assistant-secrets-file/versions/3";
  };

  nixpkgs.config.permittedInsecurePackages = [
    "python3.13-ecdsa-0.19.1"
  ];

  services.home-assistant = {
    enable = true;
    package = (pkgs.home-assistant.override { extraPackages = ps: [ ps.grpcio ]; });
    extraComponents = [
      "apple_tv"
      "brother"
      "cast"
      "esphome"
      "google_translate"
      "homekit_controller"
      "ipp"
      "met"
      "nest"
      "nws"
      "radio_browser"
      "roku"
      "samsungtv"
      "sonos"
      "spotify"
      "unifi"
      "unifiprotect"
      "xbox"
    ];
    config = {
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };

      http = {
        use_x_forwarded_for = true;
        server_host = [
          "127.0.0.1"
          "::1"
          "10.7.1.2"
        ];
        trusted_proxies = [ "::1" ];
      };

      prometheus = {
        namespace = "hass";
        requires_auth = false;
      };

      homeassistant = {
        name = "Home";
        latitude = "!secret home_lat";
        longitude = "!secret home_long";
        country = "US";
        time_zone = "America/Chicago";
        unit_system = "us_customary";
        currency = "USD";
        external_url = "https://hass.bergman.house";
      };

      zone = [
        {
          name = "Google Chicago";
          latitude = 41.8876524359147;
          longitude = -87.65266680293757;
        }
        {
          name = "High School";
          latitude = "!secret hs_lat";
          longitude = "!secret hs_long";
          icon = "mdi:school";
          radius = 220;
        }
      ];

      automation =
        let
          mkACSafety = zone: {
            alias = "AC Safety: ${zone}";
            description = "Turn off AC if local temperature falls below 60°F: ${zone}";
            triggers = [
              {
                platform = "time_pattern";
                minutes = "/20";
              }
            ];
            conditions = [
              {
                condition = "numeric_state";
                entity_id = "weather.kigq";
                attribute = "temperature";
                below = 60;
              }
              {
                condition = "state";
                entity_id = "climate.${zone}";
                state = "cool";
              }
            ];
            actions = [
              {
                service = "climate.set_hvac_mode";
                data = {
                  entity_id = "climate.${zone}";
                  hvac_mode = "off";
                };
              }
            ];
          };
        in
        [
          (mkACSafety "kitchen")
          (mkACSafety "upstairs")
        ];
    };
  };

  services.nginx.virtualHosts."hass.bergman.house" = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      proxy_buffering off;
    '';
    locations."/" = {
      proxyPass = "http://[::1]:8123";
      proxyWebsockets = true;
    };
    locations."/api/prometheus".extraConfig = ''
      return 403;
    '';
  };
}
