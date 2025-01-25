{ ... }:
{
  imports = [
    ./modules
    ./backup.nix
    ./base.nix
    ./cheddar.nix
    ./dns.nix
    ./iam.nix
    ./hedwig.nix
    ./krusty.nix
    ./mail.nix
    ./secrets.nix
    ./variables.nix

    # Pull in our WireGuard mesh network(s) spec
    ../nixos/common/global/securenets.nix
  ];
}
