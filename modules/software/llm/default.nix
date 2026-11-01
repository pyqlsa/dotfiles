{ config
, lib
, pkgs
, ...
}:
{
  imports = [
    ./llama.nix
    ./comfy.nix
    ./web.nix
    ./shared.nix
  ];
}
