{ config
, lib
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.nix = {
    enable = mkOption {
      type = types.bool;
      description = "opinionated nix settings";
      default = true;
    };
  };

  config = mkIf (cfg.nix.enable) {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 14d";
      };
    };
  };
}
