{
  description = "Configurations for @lucasbergman";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    gomod2nix,
    ...
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux"];
    pkgsFor = nixpkgs.legacyPackages;
  in {
    formatter = forAllSystems (system: pkgsFor.${system}.alejandra);

    packages = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [gomod2nix.overlays.default];
        };
      in
        import ./pkgs {inherit pkgs;}
    );

    devShells = forAllSystems (
      system: let
        pkgs = pkgsFor.${system};
      in
        import ./shell.nix {inherit inputs pkgs system;}
    );

    nixosConfigurations = {
      cheddar = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
          mypkgs = outputs.packages."x86_64-linux";
        };
        modules = [
          ./nixos/hosts/cheddar/configuration.nix
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
