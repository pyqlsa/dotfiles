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
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    #boot.initrd.availableKernelModules = [ "amdgpu" ];
    boot.initrd.kernelModules = [ "amdgpu" ];
    # opencl
    hardware.opengl.enable = true;
    # vulkan
    hardware.opengl.driSupport = true;
    # for 32-bit apps
    hardware.opengl.driSupport32Bit = true;
    hardware.opengl.extraPackages = with pkgs; [
      rocmPackages.clr
      rocmPackages.clr.icd
      # unsure if necessary
      rocmPackages.rocm-runtime
      # amdvlk in addition to mesa radv videoDrivers
      amdvlk
    ];
    hardware.opengl.extraPackages32 = with pkgs; [
      #rocmPackages.clr
      #rocmPackages.clr.icd
      # unsure if necessary
      #rocmPackages.rocm-runtime
      # amdvlk in addition to mesa radv videoDrivers
      driversi686Linux.amdvlk
    ];
    #HIP
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    # amd, pt.2
    services = mkIf (cfg.hardware.amd.graphical) {
      xserver = {
        videoDrivers = [ "amdgpu" ];
        #videoDrivers = [ "modesetting" ];
      };
    };
    sys.software = with pkgs; [
      clinfo
      rocmPackages.rocminfo
    ];
  };
}
