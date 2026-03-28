{
  description = "System configs, 'dotfiles', and... stuff";

  inputs = {
    nixpkgs = {
      #url = "github:nixos/nixpkgs/nixos-<ver>";
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/release-25.11";
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

    comfyui-nix = {
      #url = "github:pyqlsa/comfyui-nix/rocm-support";
      url = "github:pyqlsa/comfyui-nix/main";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
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
    , comfyui-nix
    , disko
    , ...
    } @ inputs:
    let
      lib = nixpkgs.lib;
      overlays = [ self.overlays.default ];
      globalModules = [
        self.nixosModules.default
        sops-nix.nixosModules.sops
        comfyui-nix.nixosModules.default
        disko.nixosModules.disko
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
          #inputs.neovim-flake.overlays.default
          comfyui-nix.overlays.default
          (final: prev: {
            neovimPQ = inputs.neovim-flake.packages.${final.stdenv.hostPlatform.system}.default;
            #ffmpeg_6-full = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.ffmpeg_6-full;
            python-basic = prev.python3.withPackages (ps: with ps;
              [ build pip setuptools twine virtualenv ]);
            python-full = prev.python3Full.withPackages (ps: with ps;
              [ build pip setuptools virtualenv twine tkinter ]);
            #viu = prev.callPackage ./pkgs/viu.nix { };
            #viu = (prev.viu.override { withSixel = true; }).overrideAttrs (oldAttrs: {
            #  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
            #    final.autoconf
            #    final.automake
            #    final.libtool
            #    final.pkg-config
            #  ];
            #});
            # gpodder on unstable doesn't build
            #gpodder = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.gpodder;
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
          python = pkgs.python-basic;
          name = "py";
        };
        py-full = import ./shells/py.nix {
          inherit pkgs;
          python = pkgs.python-full;
          name = "py-full";
        };
        krokiet = import ./shells/krokiet.nix {
          inherit pkgs;
        };
      };
    }));
}

