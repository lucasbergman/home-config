{ ... }:
{
  imports = [
    ../../modules/securenets.nix
  ];

  slb.securenets.bergnet = {
    domain = "internal.bergman.house";
    gcpDNSZone = "bergmanhouse";
    hosts = [
      {
        name = "cheddar";
        addr = "10.6.0.1";
        pubkey = "hk0sQ1CLoHX0OBr+K/C1W/dyF9DhY9vHHlM3hFGjGW4=";
        site = "linode-us-central";
        globalEndpoint = "104.237.143.66";
      }
      {
        name = "hedwig";
        addr = "10.6.0.2";
        pubkey = "/IYLz0gQbphUwzcZJyCacfe9EhuQNfd+37p6yOJSK2M=";
        site = "indiana";
        siteEndpoint = "192.168.101.3";
      }
      {
        name = "snowball";
        addr = "10.6.0.3";
        pubkey = "fjA9ariWkWqJ+v4NtfROXIqLmm0KsjS7mrkA9ULgLAE=";
        site = "indiana";
      }
    ];
  };
}
