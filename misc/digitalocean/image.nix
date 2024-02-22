let
  nixpkgsInput = (builtins.getFlake "github:lucasbergman/home-config").inputs.nixpkgs;
  pkgs = import nixpkgsInput {system = "x86_64-linux";};
  config = {
    imports = ["${pkgs.path}/nixos/modules/virtualisation/digital-ocean-image.nix"];
    system.stateVersion = "23.11";
  };
  nixos = pkgs.nixos config;
in
  nixos.digitalOceanImage
