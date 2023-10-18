{
  inputs,
  pkgs,
  system,
}: {
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs; [
      git
      go
      home-manager
      nix
      vim

      inputs.gomod2nix.packages.${system}.default
    ];
  };
}
