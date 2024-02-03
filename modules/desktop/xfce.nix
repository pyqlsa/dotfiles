{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.desktop.xfce = {
    enable = mkEnableOption (lib.mdDoc "xfce desktop");
  };

  config = mkIf (cfg.desktop.xfce.enable) {
    # xfce
    services = {
      xserver = {
        enable = true;
        desktopManager = {
          xfce.enable = true;
        };
        displayManager.defaultSession = "xfce";
        xkb.layout = "us";
      };
    };
  };
}
