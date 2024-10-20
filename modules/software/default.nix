{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./module-def.nix
    ./android.nix
    ./invokeai.nix
  ];
}
