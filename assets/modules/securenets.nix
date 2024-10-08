{
  config,
  lib,
  ...
}:
let
  networkDef = import ../../lib/types/securenets.nix;
in
{
  options.slb.securenets = lib.mkOption {
    description = "Definition of our networks";
    default = { };
    type = lib.types.attrsOf (lib.types.submodule networkDef);
  };

  config =
    let
      # Maps a network spec of the form:
      #
      #   { name = "..."; hosts = [ { name = "..."; addr = "..."; } ... ]; }
      #
      # to an attrset with one DNS record config per host:
      #
      #   {
      #     x_a_securenet = { managed_zone = "..."; type = "A"; };
      #     y_a_securenet = { ... };
      #     z_a_securenet = { ... };
      #   }
      #
      mapNetwork =
        _: netSpec:
        builtins.listToAttrs (
          builtins.map (hostSpec: {
            name = "${netSpec.gcpDNSZone}_a_securenet_${hostSpec.name}";
            value = {
              managed_zone = netSpec.gcpDNSZone;
              name = "${hostSpec.name}.${netSpec.domain}.";
              type = "A";
              rrdatas = [ hostSpec.addr ];
              ttl = 300;
            };
          }) netSpec.hosts
        );
    in
    {
      resource.google_dns_record_set =
        with lib.attrsets;
        mergeAttrsList (attrValues (mapAttrs mapNetwork config.slb.securenets));
    };
}
