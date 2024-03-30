{ inputs
, overlays
, system
, ...
}:
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
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ({ pkgs, ... }: {
      nix =
        {
          settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
          };
        };

      boot.kernelPackages = pkgs.linuxPackages_latest;

      environment.systemPackages = with pkgs; [
        nvme-cli
        smartmontools
        git
        gh
        vim
        neovimPQ
      ];
    })
  ];
}
