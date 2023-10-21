{
  description = "Configurations for @lucasbergman";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    gomod2nix,
    vscode-server,
    ...
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux"];
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

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
      system:
        import ./shell.nix {
          inherit inputs system;
          pkgs = nixpkgs.legacyPackages.${system};
          pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
        }
    );

    nixosConfigurations = {
      cheddar = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
          mypkgs = outputs.packages.x86_64-linux;
        };
        modules = [./nixos/hosts/cheddar];
      };
      hedwig = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
          mypkgs = outputs.packages.x86_64-linux;
        };
        modules = [./nixos/hosts/hedwig];
      };
    };

    homeConfigurations = {
      "lucas@hedwig" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home
          vscode-server.homeModules.default
        ];
      };
    };
  };
}
