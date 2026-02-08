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
    #boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    #boot.initrd.availableKernelModules = [ "amdgpu" ];
    boot.initrd.kernelModules = [ "amdgpu" ];

    hardware.graphics = {
      # opencl
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr
        rocmPackages.clr.icd
        # unsure if necessary
        rocmPackages.rocm-runtime
      ];
      extraPackages32 = with pkgs; [
        rocmPackages.clr
        rocmPackages.clr.icd
        # unsure if necessary
        rocmPackages.rocm-runtime
      ];
    };

    # rocm/hip
    systemd.tmpfiles.rules =
      let
        rocmEnv = pkgs.symlinkJoin {
          name = "rocm-combined";
          paths = with pkgs.rocmPackages; [
            rocblas
            hipblas
            clr
          ];
        };
      in
      [
        "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
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
      rocmPackages.amdsmi
      nvtopPackages.amd
    ];
  };
}
