{ ... }:
let
  mkRates =
    { name, counter }:
    [
      {
        record = name;
        expr = counter;
      }
    ]
    ++
      builtins.map
        (rate: {
          record = "${name}:rate${rate}";
          expr = "rate(${counter}[${rate}])";
        })
        [
          "5m"
          "15m"
          "1h"
        ];
in
{
  groups = [
    {
      name = "firewall";
      rules = builtins.concatLists [
        (mkRates {
          name = "firewall:blocked_packets";
          counter = "firewall_blocked_packets_total";
        })
        (mkRates {
          name = "firewall:blocked_bytes";
          counter = "firewall_blocked_bytes_total";
        })
      ];
    }
  ];
}
