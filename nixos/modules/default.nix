{ lib, ... }:
{
  options = {
    slb.homeNetwork.addrIPv4 = lib.mkOption {
      description = "Known IPv4 address of the house";
      type = lib.types.str;
      default = "98.227.21.195";
    };
  };

  imports = [
    ./bgpdata.nix
    ./cloudbackup.nix
    ./gcplogs.nix
    ./networking.nix
    ./nginx.nix
    ./openarc.nix
    ./security.nix
    ./unpoller.nix
  ];
}
