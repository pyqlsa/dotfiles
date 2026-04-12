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
      url = "github:pyqlsa/comfyui-nix/main";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    , llm-agents
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
          llm-agents.overlays.default
          (final: prev: {
            neovimPQ = inputs.neovim-flake.packages.${final.stdenv.hostPlatform.system}.default;
            llama-cpp = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.llama-cpp;
            llama-swap = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.llama-swap;
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

