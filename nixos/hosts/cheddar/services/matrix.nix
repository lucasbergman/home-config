{lib, ...}: let
  matrixServerName = "bergman.house";
  matrixTLSHost = "matrix.bergman.house";
  dataDirectory = "/data/matrix-synapse";
  mkVirtualHost = name: {
    useACMEHost = name;
    forceSSL = true;
    locations."/".extraConfig = ''
      return 404;
    '';
    locations."/_matrix".proxyPass = "http://[::1]:8008";
    locations."/_synapse/client".proxyPass = "http://[::1]:8008";
  };
  acmeConfig = {
    reloadServices = ["matrix-synapse.service" "nginx.service"];
    group = "nginx";
  };
in {
  security.acme.certs."${matrixServerName}" = acmeConfig;
  security.acme.certs."${matrixTLSHost}" = acmeConfig;
  services.nginx.virtualHosts = {
    "${matrixServerName}" = mkVirtualHost matrixServerName;
    "${matrixTLSHost}" = mkVirtualHost matrixTLSHost;
  };

  # Make sure that the server storage directory exists and has the right ACLs;
  # in particular, this helps if a block storage volume moves between VM
  # instances and the user/group ID for matrix-synapse changes is different.
  system.activationScripts."synapse-storage" = {
    deps = ["users" "groups"];
    text = let
      dir = lib.escapeShellArg dataDirectory;
    in ''
      if [[ ! -e ${dir} ]]; then
        install -d -m 750 -o matrix-synapse -g matrix-synapse ${dir}
      else
        chmod 750 ${dir}
        chown --recursive matrix-synapse:matrix-synapse ${dir}
      fi
    '';
  };

  services.matrix-synapse = {
    enable = true;
    dataDir = dataDirectory;
    settings = {
      server_name = matrixServerName;
      enable_metrics = true;
      media_store_path = "${dataDirectory}/media";
      database.name = "sqlite3";

      listeners = [
        {
          port = 8008;
          bind_addresses = ["::1"];
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = ["client" "federation"];
              compress = false;
            }
          ];
        }
      ];
    };
  };
}
