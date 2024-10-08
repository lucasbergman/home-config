{
  config,
  lib,
  ...
}:
let
  networkDef = import ../../lib/types/securenets.nix;
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
