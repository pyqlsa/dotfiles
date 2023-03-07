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

  # todo... still need to figure out appropriate full set of drivers
  config = mkIf (cfg.hardware.amd.enable) {
    # amd, pt.1
    boot.kernelPackages = pkgs.linuxPackages_latest;
    # amdgpu driver has x11 blank cursor bug
    boot.initrd.kernelModules = [ "amdgpu" ];
    # opencl
    hardware.opengl.enable = true;
    hardware.opengl.extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
      # unsure if necessary
      #rocm-runtime
      # amdvlk in addition to mesa radv videoDrivers
      amdvlk
    ];
    hardware.opengl.extraPackages32 = with pkgs; [
      #rocm-opencl-icd
      #rocm-opencl-runtime
      # unsure if necessary
      #rocm-runtime
      # amdvlk in addition to mesa radv videoDrivers
      driversi686Linux.amdvlk
    ];
    #HIP
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.hip}"
    ];
    # vulkan
    hardware.opengl.driSupport = true;
    # for 32-bit apps
    hardware.opengl.driSupport32Bit = true;

    # amd, pt.2
    services = mkIf (cfg.hardware.amd.graphical) {
      xserver = {
        videoDrivers = [ "amdgpu" ];
        #videoDrivers = [ "modesetting" ];
      };
    };
    sys.software = with pkgs; [
      hashcat
    ];
  };
}
