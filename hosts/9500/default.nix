{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "9500";
  networking.networkmanager.enable = true;
  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  # custom modules
  sys.desktop = {
    enable = true;
    picom.enable = true;
    i3 = {
      enable = true;
    };
    gdm = {
      enable = true;
    };
  };

  sys.hardware.audio.server = "pulse";

  system.stateVersion = "22.05";
}
