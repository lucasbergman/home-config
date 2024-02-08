{
  description = "Configurations for @lucasbergman";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    idiotbox = {
      url = "/home/lucas/hack/idiotbox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
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
    idiotbox,
    home-manager,
    gomod2nix,
    vscode-server,
    ...
  } @ inputs: let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux"];

    mkHome = system: modules:
      home-manager.lib.homeManagerConfiguration {
        inherit modules;
        pkgs = import nixpkgs {inherit system;};
        extraSpecialArgs = {
          inherit inputs;
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          mypkgs = outputs.packages.${system};
        };
      };

    mkHost = system: modules:
      nixpkgs.lib.nixosSystem {
        inherit modules;
        specialArgs = {
          inherit inputs outputs;
          mypkgs = outputs.packages.${system};
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };
      };
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    packages = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [gomod2nix.overlays.default];
        };
        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      in
        import ./pkgs {inherit pkgs pkgs-unstable;}
    );

    devShells = forAllSystems (
      system:
        import ./shell.nix {
          inherit inputs system;
          pkgs = import nixpkgs {inherit system;};
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        }
    );

    nixosConfigurations = {
      cheddar = mkHost "x86_64-linux" [./nixos/hosts/cheddar];
      hedwig = mkHost "x86_64-linux" [./nixos/hosts/hedwig idiotbox.nixosModules.default];
      snowball = mkHost "x86_64-linux" [./nixos/hosts/snowball];
    };

    homeConfigurations = {
      "lucas@hedwig" = mkHome "x86_64-linux" [./home/hedwig.nix];
      "lucas@snowball" = mkHome "x86_64-linux" [./home/snowball.nix];
    };
  };
}
