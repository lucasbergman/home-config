{ pkgs, ... }:
let
  elementHost = "element.bergman.house";
  matrixServerName = "bergman.house";
  matrixTLSHost = "matrix.bergman.house";

  elementWeb = pkgs.element-web.override {
    conf = {
      default_server_config = {
        "m.homeserver" = {
          "base_url" = "https://${matrixTLSHost}";
          "server_name" = matrixServerName;
        };
      };
    };
  };
in
{
  services.nginx.virtualHosts."${elementHost}" = {
    forceSSL = true;
    enableACME = true;
    root = elementWeb;
  };
}
