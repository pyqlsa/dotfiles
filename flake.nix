{
  description = "pyqlsa system config";

  inputs = {
    nixpkgs = {
      #url = "github:nixos/nixpkgs/nixos-23.05";
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
          # only pull in select packages from the rocm overlay
          #(final: prev: {
          #  rocm-runtime = inputs.nixos-rocm.packages.${system}.rocm-runtime;
          #  rocm-opencl-runtime = inputs.nixos-rocm.packages.${system}.rocm-opencl-runtime;
          #  rocm-opencl-icd = inputs.nixos-rocm.packages.${system}.rocm-opencl-icd;
          #  hip = inputs.nixos-rocm.packages.${system}.hip;
          #  hashcat-rocm = inputs.nixos-rocm.packages.${system}.hashcat-rocm;
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

      nixosConfigurations.wilderness = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/wilderness
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

      nixosConfigurations."9500" = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/9500
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

      nixosConfigurations.baseIso = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./iso
        ];
      };

      devShells.${system}.py = import ./shells/pip-shell.nix { inherit pkgs; };
    };
}
