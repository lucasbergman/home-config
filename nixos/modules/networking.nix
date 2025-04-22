{
  config,
  lib,
  ...
}:
{
  options.slb.networking = {
    enableSystemdNetworkd = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to use systemd-networkd for address configuration";
      default = true;
    };
  };

  config =
    let
      cfg = config.slb.networking;
    in
    lib.mkIf cfg.enableSystemdNetworkd {
      networking = {
        useDHCP = false;
        networkmanager.enable = false;
      };
      systemd.network.enable = true;
    };
}
