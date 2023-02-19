{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.hardware.amd = {
    enable = mkEnableOption (lib.mdDoc "amd gpu configurations");
    graphical = mkEnableOption (lib.mdDoc "include graphics-related amd gpu configurations");
  };

  config = mkIf (cfg.hardware.amd.enable) {
    # amd, pt.1
    #boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.kernelPackages = pkgs.linuxPackages_testing;
    #boot.initrd.kernelModules = [ "amdgpu" ];
    #boot.initrd.kernelModules = [ "modesetting" ];
    # opencl
    hardware.opengl.enable = true;
    hardware.opengl.extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
      # amdvlk in addition to mesa radv videoDrivers
      amdvlk
    ];
    # vulkan
    hardware.opengl.driSupport = true;
    # for 32-bit apps
    #hardware.opengl.driSupport32Bit = true;

    # amd, pt.2
    services = mkIf (cfg.hardware.amd.graphical) {
      xserver = {
        #videoDrivers = [ "amdgpu" ];
        videoDrivers = [ "modesetting" ];
      };
    };
  };
}
