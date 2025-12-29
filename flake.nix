{
  description = "Configurations for @lucasbergman";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    idiotbox = {
      url = "git+ssh://git@github.com/lucasbergman/idiotbox.git";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-securenets = {
      url = "github:lucasbergman/nixos-securenets";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.terranix.follows = "terranix";
    };

    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      gomod2nix,
      home-manager,
      idiotbox,
      nixos-securenets,
      terranix,
      treefmt-nix,
      vscode-server,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      mkHome =
        system: extraModules:
        home-manager.lib.homeManagerConfiguration {
          modules = [ ./home/modules ] ++ extraModules;
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            inherit vscode-server;
            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
            mypkgs = outputs.packages.${system};
          };
        };

      mkHost =
        system: hostModules:
        let
          defaultNixOSModules = [
            ./nixos/modules
            nixos-securenets.nixosModules.${system}.securenets
          ];
        in
        nixpkgs.lib.nixosSystem {
          modules = defaultNixOSModules ++ hostModules;
          specialArgs = {
            inherit inputs;
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
            mypkgs = outputs.packages.${system};
          };
        };
    in
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (pkgs.lib.getName pkg) [
              "terraform" # :(
            ];
        };

        treefmtConfig =
          let
            treefmt = treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix;
          in
          treefmt.config.build;
      in
      {
        formatter = treefmtConfig.wrapper;

        packages = import ./pkgs {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ gomod2nix.overlays.default ];
          };
        };

        apps = import ./lib/terraform-apps.nix {
          inherit pkgs;
          terraform = pkgs-unstable.terraform;
          extraModules = [ nixos-securenets.terranixModules.securenets ];
          inherit terranix;
        };

        devShells = import ./shell.nix {
          inherit
            gomod2nix
            pkgs
            pkgs-unstable
            system
            ;
        };

        checks = {
          format = treefmtConfig.check self;
        };
      }
    ))
    // {
      nixosConfigurations = {
        cheddar = mkHost "x86_64-linux" [ ./nixos/hosts/cheddar ];
        hedwig = mkHost "x86_64-linux" [
          ./nixos/hosts/hedwig
          idiotbox.nixosModules."x86_64-linux".default
        ];
        snowball = mkHost "x86_64-linux" [ ./nixos/hosts/snowball ];
      };

      homeConfigurations = {
        "lucas@hedwig" = mkHome "x86_64-linux" [ ./home/hedwig.nix ];
        "lucas@snowball" = mkHome "x86_64-linux" [ ./home/snowball.nix ];
      };
    };
}
