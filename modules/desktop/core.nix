{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.desktop = {
    enable = mkOption {
      type = types.bool;
      description = "enable desktop configurations";
      default = false;
    };
  };

  config = mkIf (cfg.desktop.enable) {
    services.xserver.libinput.enable = true;
    sys.software = with pkgs; [
      alacritty
    ];
  };
}
