{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys.steam;
in
{
  options.sys.steam = {
    enable = mkEnableOption (lib.mdDoc "enable an opinionated steam install");
  };

  config = lib.mkIf (cfg.enable) {
    programs.steam.enable = true;
    #programs.gamescopeSession.enable = true;
    #programs.gamemod.enable = true;

    programs.steam.extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    sys.software = with pkgs; [
      mangohud
      protonup-ng
    ];

    # still need to run the `protonup` command
    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${config.sys.user.name}/.steam/root/compatibilitytools.d";
    };
  };
}
