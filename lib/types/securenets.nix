{
  lib,
  ...
}:
let
  hostDef = with lib.types; {
    options = {
      name = lib.mkOption {
        description = "Short name of the host";
        type = str;
      };
      addr = lib.mkOption {
        description = "Mesh IPv4 address of the host";
        type = str;
      };
      pubkey = lib.mkOption {
        description = "WireGuard public key (base64) of the host";
        type = str;
      };
      site = lib.mkOption {
        description = "Name of the site for the host";
        type = str;
      };
      siteEndpoint = lib.mkOption {
        description = "Address of the host that is routable only within the site (null if no fixed site address)";
        type = nullOr str;
        default = null;
      };
      globalEndpoint = lib.mkOption {
        description = "Address of the host that is globally routable (null if no fixed global address)";
        type = nullOr str;
        default = null;
      };
    };
  };

  networkDef = with lib.types; {
    options = {
      domain = lib.mkOption {
        description = "Domain name for hosts in this network, e.g. internal.example.org";
        type = str;
      };
      gcpDNSZone = lib.mkOption {
        description = "Name of the zone to update in Google Cloud DNS";
        type = str;
      };
      hostBits = lib.mkOption {
        description = "Number of IPv4 host address bits on the network";
        type = addCheck int (n: n >= 8 && n <= 24);
        default = 24;
      };
      hosts = lib.mkOption {
        description = "List of host definitions in this network";
        type = listOf (submodule hostDef);
      };
    };
  };
in
networkDef
