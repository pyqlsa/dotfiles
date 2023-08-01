{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./core.nix
    ./gdm.nix
    ./i3.nix
    ./images
    ./lightdm.nix
    ./picom.nix
    ./sway.nix
    ./tiling.nix
    ./xfce.nix
  ];
}
