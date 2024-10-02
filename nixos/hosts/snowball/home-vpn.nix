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
        PrivateKeyFile = "/etc/bergmans-wg-key";
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
            # hedwig
            PublicKey = "/IYLz0gQbphUwzcZJyCacfe9EhuQNfd+37p6yOJSK2M=";
            AllowedIPs = [ "10.6.0.2" ];
            Endpoint = "192.168.101.3:51820";
            PersistentKeepalive = 20;
          };
        }
      ];
    };
    networks.bergnet0 = {
      matchConfig.Name = "bergnet0";
      address = [ "10.6.0.3/24" ];
      DHCP = "no";
      networkConfig.IPv6AcceptRA = false;
    };
  };
}
