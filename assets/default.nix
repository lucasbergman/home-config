{ ... }:
{
  imports = [
    ./backup.nix
    ./base.nix
    ./cheddar.nix
    ./dns.nix
    ./iam.nix
    ./hedwig.nix
    ./mail.nix
    ./secrets.nix
    ./snowball.nix
    ./variables.nix

    # Pull in our WireGuard mesh network(s) spec
    ../nixos/common/global/securenets.nix
  ];
}
