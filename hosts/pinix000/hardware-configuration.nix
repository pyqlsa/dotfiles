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

  boot.initrd.availableKernelModules = [ "xhci_pci" "uas" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/4a2f8723-f742-4a83-b545-cfd9d9393eab";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/4a2f8723-f742-4a83-b545-cfd9d9393eab";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/4a2f8723-f742-4a83-b545-cfd9d9393eab";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

  fileSystems."/var/log" =
    {
      device = "/dev/disk/by-uuid/4a2f8723-f742-4a83-b545-cfd9d9393eab";
      fsType = "btrfs";
      options = [ "subvol=log" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/9B6D-F473";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/373243c3-a61a-461d-8e9f-d3f0f9d12c17"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.end0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
