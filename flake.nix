{
  description = "Configurations for @lucasbergman";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    idiotbox = {
      url = "git+ssh://git@github.com/lucasbergman/idiotbox.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    terranix = {
      url = "github:terranix/terranix";
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
      terranix,
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

      defaultNixOSModules = [ ./nixos/modules ];
      mkHost =
        system: hostModules:
        nixpkgs.lib.nixosSystem {
          modules = defaultNixOSModules ++ hostModules;
          specialArgs = {
            inherit inputs outputs;
            mypkgs = outputs.packages.${system};
          } // (allPkgsOf { inherit system; });
        };
    in
    {
      formatter = forAllSystems (system: nixpkgs-unstable.legacyPackages.${system}.nixfmt-rfc-style);
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
          inherit terranix;
        }
      );

      devShells = forAllSystems (
        system: import ./shell.nix ({ inherit inputs system; } // (allPkgsOf { inherit system; }))
      );

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
