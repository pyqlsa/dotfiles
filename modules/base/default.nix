{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./nix.nix
    ./regional.nix
    ./security.nix
    ./software.nix
    ./vim.nix
    ./when-virtual.nix
  ];
}
