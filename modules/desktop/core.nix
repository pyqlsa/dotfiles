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
    # useful in most places
    services.xserver.libinput.enable = lib.mkDefault true;
    # XXX: for things that want a systray icon
    gtk.iconCache.enable = lib.mkDefault true;
    services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

    sys.software = with pkgs; [
      # referenced by default in most places
      alacritty
    ];
  };
}
