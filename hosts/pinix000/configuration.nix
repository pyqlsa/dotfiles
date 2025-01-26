{ config
, pkgs
, lib
, ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.supportedFilesystems = {
    zfs = lib.mkForce false;
  };

  #boot.kernelPackages = lib.mkForce pkgs.linuxPackages_rpi4;
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  #boot.kernelParams = [
  #  "8250.nr_uarts=1"
  #  "console=ttyAMA0,115200"
  #  "console=tty1"
  #  "cma=128M"
  #];
  #boot.loader.raspberryPi = {
  #  enable = true;
  #  version = 4;
  #};

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf;
  boot.loader.generic-extlinux-compatible.enable = true;

  hardware.firmware = with pkgs; [ firmwareLinuxNonfree ];
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;
  hardware.deviceTree = {
    enable = true;
    filter = "*rpi-4-*.dtb";
  };

  networking = {
    hostName = "pinix000";
    domain = "nochtlabs.net";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };

  # custom modules
  sys.security.sshd.enable = true;

  sys.software = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  system.stateVersion = "25.05";
}

