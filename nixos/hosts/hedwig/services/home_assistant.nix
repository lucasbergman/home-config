{ ... }:
{
  slb.security.secrets."home-assistant-secrets" = {
    before = [ "home-assistant.service" ];
    outPath = "/var/lib/hass/secrets.yaml";
    owner = "hass";
    secretPath = "projects/bergmans-services/secrets/home-assistant-secrets-file/versions/2";
  };

  services.home-assistant = {
    enable = true;
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
      "radio_browser"
      "roku"
      "samsungtv"
      "spotify"
      "unifi"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "::1" ];
      };

      homeassistant = {
        name = "Home";
        latitude = "!secret home_lat";
        longitude = "!secret home_long";
        country = "US";
        time_zone = "America/Chicago";
        unit_system = "imperial";
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
        }
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
  };
}
