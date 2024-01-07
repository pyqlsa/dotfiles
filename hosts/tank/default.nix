{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zfs
  boot.supportedFilesystems = [ "btrfs" "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.zfs.extraPools = [ "datapool" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;
  services.zfs.autoSnapshot.daily = 2;
  services.zfs.autoSnapshot.weekly = 4;

  networking = {
    hostName = "tank";
    hostId = "d63e4a0a";
    networkmanager.enable = true;
    useDHCP = false;
    interfaces = {
      enp10s0f0np0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "10.10.1.50";
            prefixLength = 24;
          }
        ];
      };
    };
    defaultGateway = "10.10.1.1";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };

  # networking.interfaces.enp10s0f1np1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp11s0u9u3c2.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;

  # custom modules
  sys.security.sshd.enable = true;

  sys.hardware.amd.enable = true;

  sys.software = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  system.stateVersion = "23.11";
}
