{ cfg }:
let
  outsideAddr = cfg.addrIPv4;
  insideInterface = "eth1";
  insideAddr = "192.168.101.3";
  insideCIDR = "192.168.101.0/24";
in
{
  service = {
    nat = {
      rule = {
        "1" = {
          description = "hairpin_https";
          destination = {
            address = outsideAddr;
            port = "443";
          };
          inbound-interface = insideInterface;
          inside-address = {
            address = insideAddr;
            port = "443";
          };
          log = "disable";
          protocol = "tcp";
          type = "destination";
        };
        "2" = {
          description = "hairpin_http";
          destination = {
            address = outsideAddr;
            port = "80";
          };
          inbound-interface = insideInterface;
          inside-address = {
            address = insideAddr;
            port = "80";
          };
          log = "disable";
          protocol = "tcp";
          type = "destination";
        };
        "5000" = {
          description = "hairpin_src";
          destination = {
            address = insideAddr;
            port = "80,443";
          };
          log = "disable";
          outbound-interface = insideInterface;
          protocol = "tcp";
          source = {
            address = insideCIDR;
          };
          type = "masquerade";
        };
      };
    };
  };
}
