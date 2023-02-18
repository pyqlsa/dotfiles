{ config
, pkgs
, lib
, ...
}:
with lib;
with builtins; let
  pape = pkgs.copyPathToStore ./pape.jpg;
in
{
  options.sys.desktop = {
    wallpaper = mkOption {
      type = types.package;
      description = "The chosen wallpaper";
      default = pape;
    };
  };
}
