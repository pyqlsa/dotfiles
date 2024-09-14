# fmwk-7850u system configuration
{ self, inputs, overlays, system, ... }:
with inputs;
let
  pkgs = import nixpkgs {
    inherit system overlays;
    config = { allowUnfree = true; };
  };
in
nixpkgs.lib.nixosSystem {
  inherit system pkgs;

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    self.nixosModules.default
    inputs.nixified-ai-flake.nixosModules.invokeai-amd
    sops-nix.nixosModules.sops
    nixos-hardware.nixosModules.framework-13-7040-amd
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.pyqlsa.imports = [ self.nixosModules.pyq-home ];
    }
  ];
}
