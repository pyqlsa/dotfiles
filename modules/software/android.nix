{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys.android;
in
{
  options.sys.android = {
    enable = mkEnableOption (lib.mdDoc "enable a collection of android client tools");
  };

  config = lib.mkIf (cfg.enable) {
    sys.software = with pkgs; [
      android-tools
      android-studio
    ];
  };
}
