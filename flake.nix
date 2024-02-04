{
  description = "pyqlsa system config";

  inputs = {
    nixpkgs = {
      #url = "github:nixos/nixpkgs/nixos-23.05";
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    home-manager = {
      #url = "github:nix-community/home-manager/release-22.11";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-flake = {
      #url = "git+ssh://git@github.com/pyqlsa/neovim-flake?ref=main";
      url = "github:pyqlsa/neovim-flake";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , nixpkgs-unstable
    , home-manager
    , neovim-flake
    , sops-nix
    , ...
    } @ inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          # (breadcrumbs) or create an overlay inline with the default package
          #(final: prev: {
          #  neovimPQ = inputs.neovim-flake.packages.${system}.default;
          #})
          inputs.neovim-flake.overlays.${system}.default
          # until patch for configure options is promoted
          (final: prev: {
            ffmpeg_6-full = inputs.nixpkgs-unstable.legacyPackages.${system}.ffmpeg_6-full;
          })
        ];
      };

      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations.fmwk-7850u = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/fmwk-7850u
          ./modules
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ ./hm-modules ];
          }
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations.wilderness = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/wilderness
          ./modules
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ ./hm-modules ];
          }
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations.tank = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/tank
          ./modules
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ ./hm-modules ];
          }
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations."9500" = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/9500
          ./modules
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ ./hm-modules ];
          }
          sops-nix.nixosModules.sops
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
            home-manager.users.pyqlsa.imports = [ ./hm-modules ];
          }
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations.baseIso = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./iso
        ];
      };

      # just home manager
      homeConfigurations = {
        pyqlsa = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ ./hm-modules ];
        };
      };

      devShells.${system}.py = import ./shells/pip-shell.nix { inherit pkgs; };
    };
}
