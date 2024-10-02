{ ... }:
{
  systemd.network = {
    netdevs."50-bergnet0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "bergnet0";
        MTUBytes = "1300";
      };
      wireguardConfig = {
        PrivateKeyFile = "/persist/etc/bergmans-wg-key";
        ListenPort = 51820;
      };
      wireguardPeers = [
        {
          wireguardPeerConfig = {
            # cheddar
            PublicKey = "hk0sQ1CLoHX0OBr+K/C1W/dyF9DhY9vHHlM3hFGjGW4=";
            AllowedIPs = [ "10.6.0.1" ];
            Endpoint = "104.237.143.66:51820";
            PersistentKeepalive = 20;
          };
        }
        {
          wireguardPeerConfig = {
            # snowball
            PublicKey = "fjA9ariWkWqJ+v4NtfROXIqLmm0KsjS7mrkA9ULgLAE=";
            AllowedIPs = [ "10.6.0.3" ];
          };
        }
      ];
    };
    networks.bergnet0 = {
      matchConfig.Name = "bergnet0";
      address = [ "10.6.0.2/24" ];
      DHCP = "no";
      networkConfig.IPv6AcceptRA = false;
    };
  };
}
