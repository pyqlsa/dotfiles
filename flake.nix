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

    flake-utils = {
      url = "github:numtide/flake-utils";
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
    , flake-utils
    , home-manager
    , neovim-flake
    , sops-nix
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
          (final: prev: {
            #neovimPQ = inputs.neovim-flake.packages.${final.system}.default;
            ffmpeg_6-full = inputs.nixpkgs-unstable.legacyPackages.${final.system}.ffmpeg_6-full;
            python-basic = prev.python311.withPackages (ps: with ps; [ pip setuptools virtualenv ]);
          })
        ];
      };

      nixosConfigurations = {
        fmwk-7850u = import ./hosts/fmwk-7850u { inherit self inputs overlays; system = "x86_64-linux"; };
        wilderness = import ./hosts/wilderness { inherit self inputs overlays; system = "x86_64-linux"; };
        tank = import ./hosts/tank { inherit self inputs overlays; system = "x86_64-linux"; };
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
        py = import ./shells/py-shell.nix {
          inherit pkgs;
          inherit (pkgs) python-basic;
        };
      };
    }));
}
