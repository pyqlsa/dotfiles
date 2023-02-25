{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./core.nix
    ./i3.nix
    ./images
    ./lightdm.nix
    ./picom.nix
    ./xfce.nix
  ];
}
