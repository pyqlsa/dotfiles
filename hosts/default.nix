{ self
, inputs
, overlays
, modules
, ...
}:
with builtins;
let
  lib = inputs.nixpkgs.lib;

  mkSystem = { hostname, system, modules }: lib.nixosSystem {
    inherit system;
    pkgs = import inputs.nixpkgs {
      inherit system overlays;
      config = { allowUnfree = true; };
    };
    modules = [
      ./${hostname}/configuration.nix
      ./${hostname}/hardware-configuration.nix
    ] ++ modules;
  };

  # { hostname = { system = "..."; modules = []; }; }
  mkNixosSystems = kvs:
    (mapAttrs
      (k: v: (mkSystem {
        hostname = k;
        system = v.system;
        modules = v.modules;
      }))
      kvs);
in
(mkNixosSystems {
  wilderness = {
    inherit modules;
    system = "x86_64-linux";
  };
  fmwk-7850u = {
    system = "x86_64-linux";
    modules = [
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ] ++ modules;
  };
  tank = {
    inherit modules;
    system = "x86_64-linux";
  };
  pinix000 = {
    system = "aarch64-linux";
    modules = [
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ] ++ modules;
  };
  "9500" = {
    inherit modules;
    system = "x86_64-linux";
  };
  nixos-wks = {
    inherit modules;
    system = "x86_64-linux";
  };
}) // {
  # nix build .#nixosConfigurations.baseIso.config.system.build.isoImage
  baseIso = import ./iso {
    inherit inputs overlays;
    system = "x86_64-linux";
  };
  # nix build .#nixosConfigurations.sd-image-rpi-generic.config.system.build.sdImage
  sd-image-rpi-generic = import ./image {
    inherit inputs overlays;
    system = "aarch64-linux";
  };
}

