{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./base
    ./desktop
    ./hardware
    ./software
    ./user
  ];
}
