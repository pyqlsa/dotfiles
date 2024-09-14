{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./module-def.nix
    ./invokeai.nix
  ];
}
