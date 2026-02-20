{ ... }:
{
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [
          "127.0.0.1"
          "::1"
          "enp3s0"
          "bergnet0"
          "nebula.bergnet"
        ];
        interface-action = [
          "enp3s0 allow"
          "bergnet0 allow"
          "nebula.bergnet allow"
        ];
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
