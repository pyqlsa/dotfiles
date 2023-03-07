{ pkgs
, lib
, config
, ...
}:
with pkgs;
with lib;
with builtins; let
  cfg = config.sys;
in
{
  options.sys.virtualisation = {
    podman = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enables podman";
      };
    };
  };

  config = mkIf (cfg.virtualisation.podman.enable == true) {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
  };
}
