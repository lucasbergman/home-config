{
  description = "Configurations for @lucasbergman";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux"];
    pkgsFor = nixpkgs.legacyPackages;
  in {
    formatter = forAllSystems (system: pkgsFor.${system}.alejandra);

    packages = forAllSystems (
      system: let
        pkgs =
          pkgsFor
          .${system};
      in
        import ./pkgs {inherit pkgs;}
    );

    devShells = forAllSystems (
      system: let
        pkgs =
          pkgsFor
          .${system};
      in
        import ./shell.nix {inherit pkgs;}
    );

    nixosConfigurations = {
      # FIXME replace with your hostname
      your-hostname = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main nixos configuration file <
          ./nixos/configuration.nix
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      # FIXME replace with your username@hostname
      "your-username@your-hostname" = home-manager.lib.homeManagerConfiguration {
        pkgs =
          pkgsFor
          .x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main home-manager configuration file <
          ./home-manager/home.nix
        ];
      };
    };
  };
}
