{...}: {
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
            # hedwig
            PublicKey = "/IYLz0gQbphUwzcZJyCacfe9EhuQNfd+37p6yOJSK2M=";
            AllowedIPs = ["10.6.0.2"];
          };
        }
      ];
    };
    networks.bergnet0 = {
      matchConfig.Name = "bergnet0";
      address = ["10.6.0.1/24"];
      DHCP = "no";
      networkConfig.IPv6AcceptRA = false;
    };
  };
}
