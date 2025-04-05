{ pkgs
, config
, lib
, ...
}:
with lib;
with builtins; let
  cfg = config.sys;
in
{
  options.sys.hardware.keyboard = {
    enable = mkEnableOption (lib.mdDoc "enable keyboard flashing and configuration tools");
  };

  config = mkIf (cfg.hardware.keyboard.enable) {
    services.udev = {
      packages = with pkgs; [
        qmk
        qmk-udev-rules
        qmk_hid
        via
        vial
      ];

    };
    hardware.keyboard.qmk.enable = true;
    sys.software = with pkgs; [
      via
    ];
  };
}
