{
  description = "pyqlsa system config";

  inputs = {
    nixpkgs = {
      #url = "github:nixos/nixpkgs/nixos-<ver>";
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/release-24.05";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    home-manager = {
      #url = "github:nix-community/home-manager/release-<nixos-ver>";
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

    nixos-hardware = {
      url = "github:nixos/nixos-hardware/master";
    };

    nixified-ai-flake = {
      url = "github:nixified-ai/flake?ref=2aeb76f52f72c7a242f20e9bc47cfaa2ed65915d";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , flake-utils
    , home-manager
    , neovim-flake
    , sops-nix
    , nixos-hardware
    , nixified-ai-flake
    , ...
    } @ inputs:
    let
      lib = nixpkgs.lib;
      overlays = [ self.overlays.default ];
      globalModules = [
        self.nixosModules.default
        inputs.nixified-ai-flake.nixosModules.invokeai-amd
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.pyqlsa.imports = [ self.nixosModules.pyq-home ];
        }
      ];
    in
    {
      nixosModules = rec {
        default = sys;
        sys = import ./modules;
        pyq-home = import ./hm-modules;
      };

      overlays = rec {
        default = packages;
        packages = lib.composeManyExtensions [
          inputs.neovim-flake.overlays.default
          #inputs.nixified-ai-flake.overlays.python-torchRocm
          (final: prev: {
            invokeai-amd = nixified-ai-flake.packages.${final.system}.invokeai-amd;
          })
          (final: prev: {
            #neovimPQ = inputs.neovim-flake.packages.${final.system}.default;
            #ffmpeg_6-full = inputs.nixpkgs-unstable.legacyPackages.${final.system}.ffmpeg_6-full;
            python-basic = prev.python3.withPackages (ps: with ps;
              [ build pip setuptools twine virtualenv ]);
            python-full = prev.python3Full.withPackages (ps: with ps;
              [ build pip setuptools virtualenv twine tkinter ]);
            # until PR for v1.5.0 is merged: https://github.com/NixOS/nixpkgs/pull/269170
            viu = prev.callPackage ./pkgs/viu.nix { };
            # gpodder on unstable doesn't build
            gpodder = inputs.nixpkgs-stable.legacyPackages.${final.system}.gpodder;
          })
        ];
      };

      nixosConfigurations = import ./hosts {
        inherit self inputs overlays;
        modules = globalModules;
      };

      # just home manager
      #homeConfigurations = {
      #  pyqlsa = home-manager.lib.homeManagerConfiguration {
      #    inherit pkgs;
      #    modules = [ self.nixosModules.pyq-home ];
      #  };
      #};
    } // (flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system overlays;
        config = { allowUnfree = true; };
      };
    in
    {
      devShells = {
        py = import ./shells/py.nix {
          inherit pkgs;
          inherit (pkgs) python-basic;
        };
        py-full = import ./shells/py-full.nix {
          inherit pkgs;
          inherit (pkgs) python-full;
        };
      };
    }));
}
