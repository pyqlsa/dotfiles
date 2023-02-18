{
  description = "pyqlsa system config";

  inputs = {
    nixpkgs = {
      #url = "github:nixos/nixpkgs/nixos-22.11";
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      #url = "github:nix-community/home-manager/release-22.11";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-flake = {
      #url = "git+ssh://git@github.com/pyqlsa/neovim-flake?ref=main";
      url = "github:pyqlsa/neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , home-manager
    , neovim-flake
    , ...
    } @ inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          inputs.neovim-flake.overlays.${system}.default
          # or create an overlay inline with the default package
          #(final: prev: {
          #  neovimPQ = inputs.neovim-flake.packages.${system}.default;
          #})
        ];
      };

      lib = nixpkgs.lib;
    in
    {
      # just home manager
      homeConfigurations = {
        pyqlsa = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./home
          ];
        };
      };

      nixosConfigurations.nixos-9500 = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/nixos-9500
          ./modules
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa = import ./home {
              inherit system lib pkgs inputs;
              inherit (pkgs) config;
            };
          }
        ];
      };

      nixosConfigurations.nixos-wks = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/nixos-wks
          ./modules
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa = import ./home {
              inherit system lib pkgs inputs;
              inherit (pkgs) config;
            };
          }
        ];
      };

      devShells.${system}.py = import ./shells/pip-shell.nix { inherit pkgs; };
    };
}
