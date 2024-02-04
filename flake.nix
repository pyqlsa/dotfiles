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
    { self
    , nixpkgs
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
        overlays = [ self.overlays.default ];
      };

      lib = nixpkgs.lib;
    in
    {
      nixosModules = rec {
        default = sys;
        sys = import ./modules;
        pyq-home = import ./hm-modules;
      };

      overlays = rec {
        default = packages;
        packages =
          final: prev: {
            neovimPQ = inputs.neovim-flake.packages.${system}.default;
            ffmpeg_6-full = inputs.nixpkgs-unstable.legacyPackages.${system}.ffmpeg_6-full;
            python-basic = pkgs.python311.withPackages (ps:
              with ps; [
                pip
                setuptools
                virtualenv
              ]);
          };
      };

      nixosConfigurations.fmwk-7850u = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/fmwk-7850u
          self.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ self.nixosModules.pyq-home ];
          }
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations.wilderness = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/wilderness
          self.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ self.nixosModules.pyq-home ];
          }
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations.tank = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/tank
          self.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ self.nixosModules.pyq-home ];
          }
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations."9500" = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/9500
          self.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ self.nixosModules.pyq-home ];
          }
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations.nixos-wks = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/nixos-wks
          self.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pyqlsa.imports = [ self.nixosModules.pyq-home ];
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
          inherit pkgs;
          modules = [ self.nixosModules.pyq-home ];
        };
      };

      devShells.${system}.py = import ./shells/py-shell.nix {
        inherit pkgs;
        inherit (pkgs) python-basic;
      };
    };
}
