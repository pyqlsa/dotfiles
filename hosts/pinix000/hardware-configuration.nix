{ config
, lib
, pkgs
, modulesPath
, ...
}: {
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "uas" "usbhid" "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/bda39398-4294-4092-95e0-6889b30260ab";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/bda39398-4294-4092-95e0-6889b30260ab";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/bda39398-4294-4092-95e0-6889b30260ab";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

  fileSystems."/var/log" =
    {
      device = "/dev/disk/by-uuid/bda39398-4294-4092-95e0-6889b30260ab";
      fsType = "btrfs";
      options = [ "subvol=log" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/C736-E238";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/cd33cabd-a9c2-40a4-b2ea-a8f2e1f1fed2"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.end0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
