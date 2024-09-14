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
            python-full = prev.python3Full.withPackages (ps: with ps; [ build pip setuptools virtualenv twine tkinter ]);
            # until PR for v1.5.0 is merged: https://github.com/NixOS/nixpkgs/pull/269170
            viu = prev.callPackage ./pkgs/viu.nix { };
            # gpodder on unstable doesn't build
            gpodder = inputs.nixpkgs-stable.legacyPackages.${final.system}.gpodder;
          })
        ];
      };

      nixosConfigurations = {
        fmwk-7850u = import ./hosts/fmwk-7850u { inherit self inputs overlays; system = "x86_64-linux"; };
        wilderness = import ./hosts/wilderness { inherit self inputs overlays; system = "x86_64-linux"; };
        tank = import ./hosts/tank { inherit self inputs overlays; system = "x86_64-linux"; };
        pinix000 = import ./hosts/pinix000 { inherit self inputs overlays; system = "aarch64-linux"; };
        "9500" = import ./hosts/9500 { inherit self inputs overlays; system = "x86_64-linux"; };
        nixos-wks = import ./hosts/nixos-wks { inherit self inputs overlays; system = "x86_64-linux"; };

        # nix build .#nixosConfigurations.baseIso.config.system.build.isoImage
        baseIso = import ./iso { inherit inputs overlays; system = "x86_64-linux"; };
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
