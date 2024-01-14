{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "wilderness";
  networking.networkmanager.enable = true;
  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;

  # custom modules
  sys.desktop = {
    enable = true;
    sway = {
      enable = true;
    };
    tiling = {
      displayConfig = ''
        output DP-1 position 0 0
        output DP-2 position 2560 0
      '';
      bar = {
        disks = [ "/" "/data" ];
      };
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

  sys.software = with pkgs; [
    hashcat
    hashcat-utils
  ];

  sops.defaultSopsFile = ../../secrets/default.yaml;
  sops.defaultSopsFormat = "yaml";
  # This will automatically import SSH keys as gpg keys
  sops.gnupg.sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
  # actual secrets
  sops.secrets.example-key = { };
  sops.secrets."example/nested" = { };
  sops.secrets."example/another" = { };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "22.11";
}
