{...}: {
  imports = [./boot.nix];

  networking = {
    usePredictableInterfaceNames = false;
    enableIPv6 = true;

    # Use sysctl to disable use of RFC 4941 IPv6 temporary addresses. Linode
    # drops outbound traffic not from the permanent address[1].
    #
    # 1. https://www.linode.com/community/questions/19157/ipv6-privacy-extensions
    tempAddresses = "disabled";
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
