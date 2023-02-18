{ config
, pkgs
, lib
, ...
}:
with lib;
with builtins; let
  cfg = config.sys;
in
{
  options.sys.software = mkOption {
    type = with types; listOf package;
    description = "List of software to install";
    default = [ ];
  };

  config = {
    environment.defaultPackages = [ ];
    environment.systemPackages = cfg.software;
  };
}
