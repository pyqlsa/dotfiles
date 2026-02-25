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
    lactSettings = lib.mkOption {
      default = { };
      type = lib.types.submodule {
        freeformType = (pkgs.formats.yaml { }).type;
      };
      description = "settings for LACT";
    };
  };

  # todo... still need to figure out appropriate full set of drivers
  config = mkIf (cfg.hardware.amd.enable) {
    # amd, pt.1
    #boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    #boot.initrd.availableKernelModules = [ "amdgpu" ];
    boot.initrd.kernelModules = [ "amdgpu" ];

    hardware.amdgpu = {
      overdrive = {
        enable = true;
        ppfeaturemask = "0xfffd7fff";
      };
      #opencl.enable = true; # don't need to set the kernel module directly
    };
    services.lact = {
      enable = true;
      settings = cfg.hardware.amd.lactSettings;
    };

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
    # only need this for packaged hard-coded to look for /opt/rocm;
    # HIP_PATH="/opt/rocm"; HIP_PLATFORM="rocm";
    systemd.tmpfiles.rules =
      let
        rocmEnv = pkgs.symlinkJoin {
          name = "rocm-combined";
          paths = with pkgs.rocmPackages; [
            rocblas
            hipblas
            clr
            rocm-runtime
            rocminfo
            hipify
          ];
        };
      in
      [
        "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
      ];

    # amd, pt.2
    services.xserver = mkIf (cfg.hardware.amd.graphical) {
      videoDrivers = [ "amdgpu" ];
      #videoDrivers = [ "modesetting" ];
    };

    sys.software = with pkgs; [
      rocmPackages.clr
      rocmPackages.rocminfo
      rocmPackages.amdsmi
      nvtopPackages.amd
      clinfo
    ];
  };
}
