{
  description = "Configurations for @lucasbergman";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
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
      url = "github:nix-community/home-manager/release-25.05";
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

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
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
      idiotbox,
      home-manager,
      gomod2nix,
      nixos-securenets,
      terranix,
      treefmt-nix,
      vscode-server,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];

      allPkgsOf =
        {
          system,
          overlays ? [ ],
        }:
        {
          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };

      mkHome =
        system: modules:
        let
          allPkgs = allPkgsOf { inherit system; };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit modules;
          inherit (allPkgs) pkgs;
          extraSpecialArgs = {
            inherit inputs;
            inherit (allPkgs) pkgs-unstable;
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
            inherit inputs outputs;
            mypkgs = outputs.packages.${system};
          } // (allPkgsOf { inherit system; });
        };

      mkTreefmt =
        system:
        let
          treefmt = treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix;
        in
        treefmt.config.build;
    in
    {
      formatter = forAllSystems (system: (mkTreefmt system).wrapper);

      packages = forAllSystems (
        system:
        import ./pkgs (allPkgsOf {
          inherit system;
          overlays = [ gomod2nix.overlays.default ];
        })
      );

      apps = forAllSystems (
        system:
        let
          allPkgs = allPkgsOf { inherit system; };
        in
        import ./lib/terraform-apps.nix {
          pkgs = allPkgs.pkgs;
          terraform = allPkgs.pkgs-unstable.terraform;
          extraModules = [ nixos-securenets.terranixModules.securenets ];
          inherit terranix;
        }
      );

      devShells = forAllSystems (
        system: import ./shell.nix ({ inherit inputs system; } // (allPkgsOf { inherit system; }))
      );

      checks = forAllSystems (system: {
        format = (mkTreefmt system).check self;
      });

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
