{ ... }:
{
  networking = {
    usePredictableInterfaceNames = false;
    enableIPv6 = true;
  };

  systemd.network = {
    networks."10-wan" = {
      # The public interface on Linode is always eth0
      matchConfig.Name = "eth0";

      # Turn on DHCP for IPv4 and SLAAC for IPv6
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };

      # This link must be routable as a dependency of network-online.target
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
