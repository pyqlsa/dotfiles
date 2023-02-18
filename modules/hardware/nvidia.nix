{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.hardware.nvidia = {
    enable = mkEnableOption (lib.mdDoc "nvidia gpu configurations");
    graphical = mkEnableOption (lib.mdDoc "include graphics-related nvidia gpu configurations");
  };

  config = mkIf (cfg.hardware.nvidia.enable) {
    # nvidia, pt.1
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
    hardware.nvidia.powerManagement.enable = true;
    hardware.opengl.enable = true;

    # xfce
    # nvidia, pt.2
    services = mkIf (cfg.hardware.nvidia.graphical) {
      xserver = {
        videoDrivers = [ "nvidia" ];
        screenSection = ''
          Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
          Option         "AllowIndirectGLXProtocol" "off"
          Option         "TripleBuffer" "on"
        '';
      };
    };
  };
}
