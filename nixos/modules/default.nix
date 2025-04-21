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
    ./cloudbackup.nix
    ./gcplogs.nix
    ./nginx.nix
    ./security.nix
    ./unpoller.nix
  ];
}
