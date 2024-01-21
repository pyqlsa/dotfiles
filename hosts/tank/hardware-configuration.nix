{ config
, lib
, pkgs
, modulesPath
, ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "mpt3sas" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    #device = "/dev/disk/by-uuid/abcf3330-b028-41e4-8c48-add2877f60fb";
    device = "/dev/disk/by-label/nix-root";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    #device = "/dev/disk/by-uuid/abcf3330-b028-41e4-8c48-add2877f60fb";
    device = "/dev/disk/by-label/nix-root";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    #device = "/dev/disk/by-uuid/abcf3330-b028-41e4-8c48-add2877f60fb";
    device = "/dev/disk/by-label/nix-root";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    #device = "/dev/disk/by-uuid/abcf3330-b028-41e4-8c48-add2877f60fb";
    device = "/dev/disk/by-label/nix-root";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    #device = "/dev/disk/by-uuid/D7C8-6BE4";
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [
    {
      #device = "/dev/disk/by-uuid/7ec288eb-0307-4f51-9c44-577a9d6e0a36";
      device = "/dev/disk/by-label/swap";
    }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp10s0f0np0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp10s0f1np1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp11s0u9u3c2.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
