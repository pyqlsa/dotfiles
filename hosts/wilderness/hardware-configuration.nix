{ config
, lib
, pkgs
, modulesPath
, ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "thunderbolt" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."enc" = {
    #device = "/dev/disk/by-uuid/cbd330ed-a0fd-4897-833a-bbbf69d8c84d";
    device = "/dev/disk/by-label/nix-enc-root";
  };

  fileSystems."/" = {
    #device = "/dev/disk/by-uuid/df6e0a4a-b617-4542-9787-cda7cc493071";
    device = "/dev/disk/by-label/nix-root";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/nix-root";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nix-root";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-label/nix-root";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    #device = "/dev/disk/by-uuid/2064-F10F";
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  boot.initrd.luks.devices."enc-data" = {
    device = "/dev/disk/by-label/enc-data";
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" ];
  };

  boot.initrd.luks.devices."enc-big-data" = {
    device = "/dev/disk/by-label/enc-big-data";
  };

  fileSystems."/big-data" = {
    device = "/dev/disk/by-label/big-data";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" ];
  };

  swapDevices = [
    {
      #device = "/dev/disk/by-uuid/67c5d97b-cc8c-4e07-8ddb-d3f8e05554d5";
      device = "/dev/disk/by-label/swap";
      encrypted = {
        enable = true;
        keyFile = "/mnt-root/root/swap.key";
        label = "nix-enc-swap";
        #blkDev = "/dev/disk/by-uuid/61858d3f-fb9d-4580-947e-94f2fbb7aad3";
        blkDev = "/dev/disk/by-label/nix-enc-swap";
      };
    }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
