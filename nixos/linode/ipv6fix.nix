{ ... }:
{
  # Linode, like all cloud hosts, strictly binds IP traffic to instances/MACs and drops
  # outbound traffic not coming from assigned addresses[1]. But by default
  # systemd-networkd tells the kernel to prefer RFC 4941 temporary addresses for better
  # privacy for client traffic, which causes all our traffic to go nowhere on Linode.
  #
  # 1. https://www.linode.com/community/questions/19157/ipv6-privacy-extensions

  # Directly sets ipv6.conf.*.use_tempaddr sysctl to 0
  networking.tempAddresses = "disabled";

  # Anecdotally, systemd-networkd starts racing with the above at some point around
  # NixOS 25.11, so also do this thing that we should have done in the first place
  systemd.network = {
    networks."10-wan" = {
      networkConfig.IPv6PrivacyExtensions = "no";
    };
  };
}
