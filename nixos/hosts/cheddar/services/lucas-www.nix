{ ... }:
{
  services.nginx.virtualHosts."lucas.bergman.house" = {
    forceSSL = true;
    enableACME = true;

    root = "/var/www/lucas";
  };
}
