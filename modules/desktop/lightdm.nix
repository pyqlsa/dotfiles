{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.desktop.lightdm = {
    enable = mkEnableOption (lib.mdDoc "opinionated lightdm configurations");
    background = mkOption {
      type = types.package;
      description = "Background image to use";
      default = cfg.desktop.wallpaper;
    };
  };

  config = mkIf cfg.desktop.lightdm.enable {
    services = {
      xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = lib.mkDefault false;
        };
        displayManager.lightdm = {
          enable = true;
          background = cfg.desktop.lightdm.background;
          greeters.slick = {
            enable = true;
            extraConfig = ''
              draw-grid=true
              show-hostname=true
              show-keyboard=true
              show-a11y=true
              show-power=true
              show-clock=true
              show-quit=true
            '';
          };
        };
      };
    };
  };
}
