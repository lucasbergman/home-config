{ config, lib, ... }:
let
  nebulaIp = config.slb.nebula.ip;
  hasNebula = config.slb.nebula.enable && nebulaIp != null;
in
{
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [
          "127.0.0.1"
          "::1"
          "enp3s0"
        ]
        ++ lib.optional hasNebula nebulaIp;
        interface-action = [
          "enp3s0 allow"
        ]
        ++ lib.optional hasNebula "nebula.bergnet allow";
        # Allow binding to the Nebula IP address even if the nebula.bergnet interface
        # is not yet created/up at startup (uses Linux IP_FREEBIND socket option)
        ip-freebind = true;
      };
      forward-zone = [
        {
          name = "priv.bergman.house.";
          forward-addr = "10.7.1.1";
        }
        {
          name = ".";
          forward-addr = [
            # TODO: Does Comcast support DoT or DoH?
            "75.75.75.75"
            "75.75.76.76"
          ];
        }
      ];
    };
  };
}
