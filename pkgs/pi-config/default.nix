{ lib, pkgs }:

let
  # Copy config files directly into the store so we can bind them into the jail.
  # This bypasses home-manager's symlink chain while keeping everything declarative.
  settings-json = pkgs.writeText "pi-settings.json" (builtins.readFile ./settings.json);
  models-json = pkgs.writeText "pi-models.json" (builtins.readFile ./models.json);

  # Copy the packages directory recursively into the store.
  # TODO: actually package these things for real
  pi-packages = pkgs.stdenvNoCC.mkDerivation {
    name = "pi-agent-packages";
    src = ./packages;
    installPhase = ''
      mkdir -p $out
      cp -r --no-preserve=mode,ownership --dereference $src/* $out/
    '';
  };

in
{
  inherit settings-json models-json pi-packages;
}
