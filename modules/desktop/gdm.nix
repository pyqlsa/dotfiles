{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.desktop.gdm = {
    enable = mkEnableOption (lib.mdDoc "opinionated gdm configurations");
    background = mkOption {
      type = types.package;
      description = "Background image to use";
      default = cfg.desktop.wallpaper;
    };
  };

  config = mkIf cfg.desktop.gdm.enable {
    services = {
      xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = lib.mkDefault false;
        };
        displayManager.gdm = {
          enable = true;
        };
      };
    };
  };
}
