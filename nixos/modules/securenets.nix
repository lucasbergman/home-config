{
  config,
  lib,
  ...
}:
let
  hostDef = with lib.types; {
    options = {
      name = lib.mkOption {
        description = "Short name of the host";
        type = str;
      };
      addr = lib.mkOption {
        description = "Mesh IPv4 address of the host";
        type = str;
      };
      pubkey = lib.mkOption {
        description = "WireGuard public key (base64) of the host";
        type = str;
      };
      site = lib.mkOption {
        description = "Name of the site for the host";
        type = str;
      };
      siteEndpoint = lib.mkOption {
        description = "Address of the host that is routable only within the site (null if no fixed site address)";
        type = nullOr str;
        default = null;
      };
      globalEndpoint = lib.mkOption {
        description = "Address of the host that is globally routable (null if no fixed global address)";
        type = nullOr str;
        default = null;
      };
    };
  };

  networkDef = with lib.types; {
    options = {
      domain = lib.mkOption {
        description = "Domain name for hosts in this network, e.g. internal.example.org";
        type = str;
      };
      gcpDNSZone = lib.mkOption {
        description = "Name of the zone to update in Google Cloud DNS";
        type = str;
      };
      hostBits = lib.mkOption {
        description = "Number of IPv4 host address bits on the network";
        type = addCheck int (n: n >= 8 && n <= 24);
        default = 24;
      };
      hosts = lib.mkOption {
        description = "List of host definitions in this network";
        type = listOf (submodule hostDef);
      };
    };
  };
in
{
  options.slb.securenets = lib.mkOption {
    description = "Definition of our networks";
    default = { };
    type = lib.types.attrsOf (lib.types.submodule networkDef);
  };

  options.slb.securenet = with lib.types; {
    enable = lib.mkOption {
      description = "Whether to enable WireGuard secure mesh network support";
      default = false;
      type = bool;
    };

    network = lib.mkOption {
      description = "Name of the network to join (from `slb.securenets`)";
      type = str;
    };

    myName = lib.mkOption {
      description = "Short name that identifies this host on the mesh";
      default = config.networking.hostName;
      type = str;
    };

    privateKeyPath = lib.mkOption {
      description = "Path to WireGuard private key file";
      type = str;
    };
  };

  config =
    let
      cfg = config.slb.securenet;
      netname = cfg.network;
      getSingle =
        pred: list:
        let
          found = builtins.filter pred list;
        in
        assert builtins.length found == 1;
        builtins.head found;
      myNet = config.slb.securenets."${netname}";
      myHost = getSingle (h: h.name == cfg.myName) myNet.hosts;
      peerHosts = builtins.filter (h: h.name != cfg.myName) myNet.hosts;

      peerAddrOf =
        p:
        if (p.site == myHost.site && p.siteEndpoint != null) then
          p.siteEndpoint
        else
          (if p.globalEndpoint != null then p.globalEndpoint else null);

      shouldKeepaliveTo =
        p:
        (
          (p.site == myHost.site && myHost.siteEndpoint == null)
          || (p.site != myHost.site && myHost.globalEndpoint == null)
        );

      mkPeer = peerHost: {
        wireguardPeerConfig =
          let
            peerAddr = peerAddrOf peerHost;
          in
          lib.attrsets.filterAttrs (_: v: v != null) {
            PublicKey = peerHost.pubkey;
            AllowedIPs = [ peerHost.addr ];
            Endpoint = if peerAddr != null then "${peerAddr}:51820" else null;
            PersistentKeepalive = if peerAddr != null && (shouldKeepaliveTo peerHost) then 20 else null;
          };
      };
    in
    lib.mkIf cfg.enable {
      systemd.network = {
        netdevs."50-${netname}0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "${netname}0";
            MTUBytes = "1300";
          };
          wireguardConfig = {
            PrivateKeyFile = cfg.privateKeyPath;
            ListenPort = 51820;
          };
          wireguardPeers = builtins.map mkPeer peerHosts;
        };
        networks."${netname}0" = {
          matchConfig.Name = "${netname}0";
          address = [ "${myHost.addr}/${builtins.toString myNet.hostBits}" ];
          DHCP = "no";
          networkConfig.IPv6AcceptRA = false;
        };
      };
    };
}
