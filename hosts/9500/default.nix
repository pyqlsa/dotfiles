# 9500 system configuration
{ self, inputs, overlays, ... }:
let
  system = "x86_64-linux";
in
with inputs;

nixpkgs.lib.nixosSystem {
  inherit system;

  pkgs = import nixpkgs {
    inherit system overlays;
    config = { allowUnfree = true; };
  };

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    self.nixosModules.default
    sops-nix.nixosModules.sops
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.pyqlsa.imports = [ self.nixosModules.pyq-home ];
    }
  ];
}
