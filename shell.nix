{
  inputs,
  pkgs,
  pkgs-unstable,
  system,
}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";

    nativeBuildInputs = [
      pkgs.git
      pkgs.go
      pkgs.home-manager
      pkgs.jq
      pkgs.nix
      pkgs.nvd
      pkgs.sops
      pkgs.ssh-to-age
      pkgs.vim

      # These packages have actively packaging and otherwise fast-moving
      # upstreams, so pulling from nixpkgs-unstable seems wise
      pkgs-unstable.bitwarden-cli
      pkgs-unstable.google-cloud-sdk
      pkgs-unstable.terraform

      inputs.gomod2nix.packages.${system}.default
    ];
  };
}
