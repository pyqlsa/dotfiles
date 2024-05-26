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
    services.libinput.enable = lib.mkDefault true;
    # XXX: for things that want a systray icon
    gtk.iconCache.enable = lib.mkDefault true;
    services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

    programs.mtr.enable = true;

    sys.software = with pkgs; [
      # referenced by default in most places
      alacritty
      sops
    ];

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = lib.mkForce pkgs.pinentry-qt;
    };

    services.pcscd.enable = true;


    programs.tmux = {
      enable = true;
      clock24 = true;
      keyMode = "emacs"; # or vi
      #terminal = "tmux-256color";
      extraConfig = ''
        set -g default-terminal "tmux-256color"
        set -ga terminal-overrides ",*256col*:Tc"
        set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
        set-environment -g COLORTERM "truecolor"
      '';
    };

  };
}
