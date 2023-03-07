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
    ./virt.nix
    ./when-virtual.nix
  ];
}
