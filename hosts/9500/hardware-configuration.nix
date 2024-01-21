{ config
, lib
, pkgs
, modulesPath
, ...
}:
let
  thermald-conf = ./thermald-conf.xml;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "btrfs" ];
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # tmp
  boot.tmp.useTmpfs = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/23111bb2-ae0f-44cd-80d8-87f9f96bc3e8";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  boot.initrd.luks.devices."enc".device = "/dev/disk/by-uuid/666a03e0-d659-4436-afb4-a57fa7f7042f";

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/23111bb2-ae0f-44cd-80d8-87f9f96bc3e8";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/23111bb2-ae0f-44cd-80d8-87f9f96bc3e8";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/23111bb2-ae0f-44cd-80d8-87f9f96bc3e8";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F822-1626";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/2f592e96-d0a4-4590-ba38-afc283fc4303";
      encrypted = {
        enable = true;
        keyFile = "/mnt-root/root/swap.key";
        label = "encswap";
        blkDev = "/dev/disk/by-uuid/88380cd4-02ee-49b9-b79c-3c5c4f3c71c3";
      };
    }
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.acpilight.enable = true;
  # 9500-specific
  # Boot loader
  boot.kernelParams = lib.mkDefault [ "acpi_rev_override" ];

  # This will save you money and possibly your life!
  services.thermald.enable = lib.mkDefault true;

  # Thermald doesn't have a default config for the 9500 yet, the one in this repo
  # was generated with dptfxtract-static (https://github.com/intel/dptfxtract)
  services.thermald.configFile = lib.mkDefault thermald-conf;

  # WiFi speed is slow and crashes by default (https://bugzilla.kernel.org/show_bug.cgi?id=213381)
  # disable_11ax - required until ax driver support is fixed
  # power_save - works well on this card
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=1 disable_11ax=1
  '';
  # end 9500 specific

  # intel gpu
  boot.initrd.kernelModules = [ "i915" ];
  services.xserver = {
    videoDrivers = [ "intel" ];
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };

  environment.variables = {
    VDPAU_DRIVER = lib.mkIf (config.hardware.opengl.enable) (lib.mkDefault "va_gl");
  };

  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    libvdpau-va-gl
    intel-media-driver
  ];
  # end intel gpu

  # disable nvidia, very nice battery life.
  hardware.nvidiaOptimus.disable = lib.mkDefault true;
  boot.blacklistedKernelModules = lib.mkDefault [ "nouveau" "nvidia" ];
  # end disable nvidia
}
