{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos-9500";
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
      wifiInterface = "wlp0s20f3";
      showPower = true;
    };
    lightdm = {
      enable = true;
    };
  };

  sys.hardware.audio.server = "pulse";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "22.05";
}
