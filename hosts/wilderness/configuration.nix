{ config
, lib
, pkgs
, ...
}: {
  networking.hostName = "wilderness";
  networking.networkmanager.enable = true;
  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;

  # allow to build some arm things
  # `pkgs.crossSystem.system = "aarch64-linux";`?
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

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
      # swaymsg -t get_inputs
      inputConfig = ''
        input 4152:6194:SteelSeries_SteelSeries_Sensei_Ten {
          natural_scroll disabled
          accel_profile "flat" # disable mouse acceleration (enabled by default; to set it manually, use "adaptive" instead of "flat")
          pointer_accel 0.1 # set mouse sensitivity (between -1 and 1)
          scroll_factor 0.6 # set scroll sensitivity (positive floating point)
        }
      '';
      bar = {
        disks = [ "/" "/data" "/big-data" ];
      };
    };
    gdm = {
      enable = true;
    };
  };

  sys.hardware = {
    amd = {
      enable = true;
      graphical = true;
    };
    audio.server = "pipewire";
  };

  sys.security.sshd.enable = true;

  sys.virtualisation.virt-manager.enable = true;

  sys.software = with pkgs; [
    hashcat
    hashcat-utils
  ];

  sys.android.enable = true;

  sops.defaultSopsFile = ../../secrets/default.yaml;
  sops.defaultSopsFormat = "yaml";
  # This will automatically import SSH keys as gpg keys
  sops.gnupg.sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
  # actual secrets
  sops.secrets."vpn/protonvpn/creds" = { };
  sops.secrets."vpn/protonvpn/certificate" = { };
  sops.secrets."vpn/protonvpn/key" = { };

  sys.protonvpn =
    let
      commonOpts = {
        updateResolvConf = true;
        server = {
          address = "146.70.174.146";
          ports = [ 51820 5060 80 4569 1194 ];
        };
        openvpnCreds = config.sops.secrets."vpn/protonvpn/creds".path;
        openvpnCertificate = config.sops.secrets."vpn/protonvpn/certificate".path;
        openvpnKey = config.sops.secrets."vpn/protonvpn/key".path;
      };
    in
    {
      proton-strict = {
        autostart = false;
      } // commonOpts;
      proton-allow-local = {
        autostart = true;
        localNets = [
          { net = "10.10.0.0"; mask = "255.255.0.0"; }
          { net = "10.5.0.0"; mask = "255.255.0.0"; }
          { net = "10.200.0.0"; mask = "255.255.0.0"; }
          { net = "10.0.0.0"; mask = "255.255.0.0"; }
        ];
        extraDns = [ "10.10.1.1" ];
      } // commonOpts;
    };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "22.11";
}
