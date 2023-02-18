{ config
, lib
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.virt = {
    enable = mkOption {
      type = types.bool;
      description = "opinionated vm settings when system is a virtual machine";
      default = true;
    };

    cores = mkOption {
      type = types.int;
      description = "Number of cores to allocate to the qemu vm";
      default = 4;
    };

    memorySize = mkOption {
      type = types.int;
      description = "Amount of memory to allocate to the qemu vm (in MB)";
      default = 4096;
    };
  };

  config = mkIf (cfg.virt.enable) {
    virtualisation.vmVariant = {
      virtualisation = {
        memorySize = cfg.virt.memorySize;
        cores = cfg.virt.cores;
      };
    };
  };
}
