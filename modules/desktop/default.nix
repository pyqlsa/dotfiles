{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./core.nix
    ./gnome.nix
    ./i3.nix
    ./images
    ./picom.nix
    ./xfce.nix
  ];
}
