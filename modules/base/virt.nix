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
    virt-manager = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enables virt-manager";
      };
    };
  };

  config = {
    # podman
    virtualisation.podman = mkIf (cfg.virtualisation.podman.enable) {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };

    # virt-manager
    virtualisation.libvirtd.enable = cfg.virtualisation.virt-manager.enable;
    # other things might use dconf, so don't strictly bind to option value
    programs.dconf.enable = mkIf (cfg.virtualisation.virt-manager.enable) true;
    sys.software = [
      (mkIf (cfg.virtualisation.virt-manager.enable) virt-manager)
    ];
  };
}
