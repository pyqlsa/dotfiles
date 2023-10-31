{ config
, lib
, pkgs
, ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # try to get keyboard brightnessctl working
  boot.blacklistedKernelModules = [ "hid_sensor_hub" ];

  networking.hostName = "fmwk-7850u";
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # while framework matures their lvfs support
  services.fwupd.extraRemotes = [ "lvfs-testing" ];

  # custom modules
  sys.desktop = {
    enable = true;
    sway = {
      enable = true;
    };
    tiling = {
      bar = {
        disks = [ "/" ];
      };
      displayConfig = ''
        output eDP-1 scale 1.5
      '';
      inputConfig = ''
        input 2362:628:PIXA3854:00_093A:0274_Touchpad {
          left_handed enabled
          tap enabled
          natural_scroll disabled
          dwt enabled
          accel_profile "flat" # disable mouse acceleration (enabled by default; to set it manually, use "adaptive" instead of "flat")
          pointer_accel 0.5 # set mouse sensitivity (between -1 and 1)
          scroll_factor 0.3 # set scroll sensitivity (positive floating point)
        }
      '';
    };
    gdm = {
      enable = true;
    };
  };

  sys.hardware.amd = {
    enable = true;
    graphical = true;
  };

  sys.hardware.audio.server = "pipewire";

  sys.security.sshd.enable = true;

  sys.virtualisation.virt-manager.enable = true;

  system.stateVersion = "23.11";
}
