{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./amd.nix
    ./audio.nix
    ./bluetooth.nix
    ./disk.nix
    ./firmware.nix
    ./keyboard.nix
    ./nvidia.nix
    ./software.nix
  ];
}
