{ ... }:
{
  # Local recursive DNS resolver. Normally it'd be a bit faster to forward queries to
  # Linode's resolvers instead of doing full recursion, but we rely on a ton of DNS
  # queries for DNSBL lookups, and shared resolvers constantly get rate-limited.
  services.unbound = {
    enable = true;
    settings.server = {
      interface = [
        "127.0.0.1"
        "::1"
      ];
      access-control = [
        "127.0.0.0/8 allow"
        "::1/128 allow"
      ];
    };
    # No forward-zone means full recursive resolution
  };

  # Don't use systemd-resolved
  services.resolved.enable = false;

  # Don't use DHCP-provided DNS
  systemd.network.networks."10-wan".dhcpV4Config.UseDNS = false;

  # Use local resolver for system DNS
  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];
}
