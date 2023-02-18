{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.desktop.picom = {
    enable = mkEnableOption (lib.mdDoc "picom configurations");
  };

  config = mkIf (cfg.desktop.picom.enable) {
    services = {
      picom = {
        enable = true;
        fade = true;
        inactiveOpacity = 0.95;
        shadow = true;
        fadeDelta = 4;
      };
    };
  };
}
