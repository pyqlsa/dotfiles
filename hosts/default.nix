{ self
, inputs
, overlays
, modules
, ...
}:
with builtins;
let
  lib = inputs.nixpkgs.lib;

  sdImageOptionsModule = ({ pkgs, config, ... }: {
    sdImage.compressImage = false;
  });

  mkSystem = { hostname, system, modules, cudaSupport ? false, rocmSupport ? false }: lib.nixosSystem {
    inherit system;
    pkgs = import inputs.nixpkgs {
      inherit system overlays;
      config = {
        inherit cudaSupport rocmSupport;
        allowUnfree = true;
        permittedInsecurePackages = [
          "libsoup-2.74.3" # XXX
        ];
      };
    };
    modules = [
      ./${hostname}/configuration.nix
    ] ++ modules;
  };

  # { hostname = { system = "..."; modules = []; }; }
  mkNixosSystems = kvs:
    (mapAttrs
      (k: v: (mkSystem {
        hostname = k;
        system = v.system;
        modules = v.modules;
        cudaSupport = if v ? cudaSupport then v.cudaSupport else false;
        rocmSupport = if v ? rocmSupport then v.rocmSupport else false;
      }))
      kvs);
in
(mkNixosSystems {
  wilderness = {
    inherit modules;
    system = "x86_64-linux";
    # hmmm... strange crashes observed in ollama when using rocm-compiled packages;
    # hashcat seemed to work nicely, though
    rocmSupport = false;
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
      #"${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
      #sdImageOptionsModule
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
  # generic artifacts (potentially) useful for non-tailored systems
  #
  # nix build .#nixosConfigurations.x86-iso.config.system.build.isoImage
  x86-iso = import ./installer {
    inherit inputs overlays;
    system = "x86_64-linux";
    install-base = "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix";
  };
  # nix build .#nixosConfigurations.aarch64-iso.config.system.build.isoImage
  aarch64-iso = import ./installer {
    inherit inputs overlays;
    system = "aarch64-linux";
    install-base = "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix";
  };
  # nix build .#nixosConfigurations.sd-image-rpi-generic.config.system.build.sdImage
  sd-image-rpi-generic = import ./installer {
    inherit inputs overlays;
    system = "aarch64-linux";
    #install-base = "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix";
    install-base = "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix";
    extra-modules = [
      sdImageOptionsModule
    ];
  };
}

