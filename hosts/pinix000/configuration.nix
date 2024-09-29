{ config
, pkgs
, lib
, ...
}: {
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_rpi4;
  boot.kernelParams = [
    "8250.nr_uarts=1"
    "console=ttyAMA0,115200"
    "console=tty1"
    "cma=128M"
  ];
  boot.loader.raspberryPi = {
    enable = true;
    version = 4;
  };
  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf;
  # commenting out in favor of rpi4 configs
  # boot.loader.generic-extlinux-compatible.enable = true;
  hardware.firmware = with pkgs; [ firmwareLinuxNonfree ];
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "pinix000";
    domain = "nochtlabs.net";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };

  # custom modules
  sys.security.sshd.enable = true;

  system.stateVersion = "23.05";
}

