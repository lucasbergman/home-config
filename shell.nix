{
  pkgs,
  pkgs-unstable,
  system,
  gomod2nix,
}:
{
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";

    nativeBuildInputs = [
      pkgs.dnsutils
      pkgs.git
      pkgs.go
      pkgs.home-manager
      pkgs.jq
      pkgs.nix
      pkgs.nvd
      pkgs.sops
      pkgs.ssh-to-age
      pkgs.terranix

      # These packages have actively packaging and otherwise fast-moving
      # upstreams, so pulling from nixpkgs-unstable seems wise
      pkgs-unstable.google-cloud-sdk
      pkgs-unstable.terraform

      gomod2nix.packages.${system}.default
    ];
  };
}
