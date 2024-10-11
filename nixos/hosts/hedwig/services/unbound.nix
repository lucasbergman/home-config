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
        ];
        interface-action = [
          "enp3s0 allow"
          "bergnet0 allow"
        ];
      };
      forward-zone = [
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
