{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.desktop.gnome = {
    enable = mkEnableOption (lib.mdDoc "gnome desktop");
  };

  config = mkIf (cfg.desktop.gnome.enable) {
    # Enable the X11 windowing system and gnome.
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    environment.gnome.excludePackages =
      (with pkgs; [
        #gnome-photos
        gnome-tour
      ])
      ++ (with pkgs.gnome; [
        cheese # webcam tool
        gnome-music
        #gnome-terminal
        gedit # text editor
        epiphany # web browser
        geary # email reader
        evince # document viewer
        gnome-characters
        #totem # video player
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
      ]);
  };
}
