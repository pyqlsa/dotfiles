{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./disk.nix
    ./firmware.nix
    ./nvidia.nix
    ./software.nix
  ];
}
