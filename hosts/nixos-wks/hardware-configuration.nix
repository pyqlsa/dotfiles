{ config
, lib
, pkgs
, modulesPath
, ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "k10temp" "it87" ]; # extra modules primarily for conky
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "btrfs" ];
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/46c0c723-791a-4c04-89a2-836c07ddb200";
    fsType = "btrfs";
    options = [ "subvol=root" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/46c0c723-791a-4c04-89a2-836c07ddb200";
    fsType = "btrfs";
    options = [ "subvol=home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/46c0c723-791a-4c04-89a2-836c07ddb200";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/46c0c723-791a-4c04-89a2-836c07ddb200";
    fsType = "btrfs";
    options = [ "subvol=log" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/04F2-4E54";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/be91dcce-c7bf-4429-b521-722a99e22399"; }
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
