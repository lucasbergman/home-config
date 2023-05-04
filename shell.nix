{
  inputs,
  pkgs,
  system,
}: {
  default = pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      git
      go
      home-manager
      nix

      inputs.gomod2nix.packages.${system}.default
    ];
  };
}
