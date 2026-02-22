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

  # allow to build some arm things
  # `pkgs.crossSystem.system = "aarch64-linux";`?
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  sops.defaultSopsFile = ../../secrets/default.yaml;
  sops.defaultSopsFormat = "yaml";
  # This will automatically import SSH keys as gpg keys
  sops.gnupg.sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
  # actual secrets
  sops.secrets."vpn/protonvpn/creds" = { };
  sops.secrets."vpn/protonvpn/certificate" = { };
  sops.secrets."vpn/protonvpn/key" = { };
  sops.secrets."searxng/secretVals" = { };

  # custom modules
  sys.desktop = {
    enable = true;
    sway = {
      enable = true;
    };
    tiling = {
      displayConfig = ''
        set $disp1 "DP-1"
        set $disp2 "DP-2"

        output $dsip1 position 0 0
        output $disp2 position 2560 0

        #workspace 1 output $disp1
        #workspace 2 output $disp2
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
      lactSettings = {
        version = 5;
        daemon = {
          log_level = "info";
          admin_group = "wheel";
          disable_clocks_cleanup = false;
        };
        apply_settings_timer = 5;
        gpus = {
          "1002:744C-1849:5333-0000:03:00.0" = {
            fan_control_enabled = false;
            performance_level = "auto";
            max_core_clock = 2910;
            voltage_offset = -100;
          };
          "1002:744C-1849:5333-0000:07:00.0" = {
            fan_control_enabled = false;
            performance_level = "auto";
            max_core_clock = 2910;
            voltage_offset = -100;
          };
        };
        current_profile = null;
        auto_switch_profiles = false;
      };
    };
    audio = {
      server = "pipewire";
      scarlett.enable = true;
    };
    keyboard.enable = true;
  };

  sys.steam.enable = true;

  sys.security.sshd.enable = true;

  sys.virtualisation = {
    virt-manager.enable = true;
    podman.enable = true;
  };

  sys.software = with pkgs; [
    hashcat
    hashcat-utils
  ];

  sys.llm = {
    enable = true;
    web = {
      enable = true;
    };
    comfy = {
      enable = true;
      extraArgs = [
        "--disable-xformers"
        "--use-pytorch-cross-attention"
        "--normalvram"
        "--reserve-vram"
        "1"
        "--cuda-device"
        "1"
      ];
    };
    searxng = {
      enable = true;
      environmentFile = config.sops.secrets."searxng/secretVals".path;
    };
  };

  sys.android.enable = true;

  sys.protonvpn =
    let
      commonOpts = {
        updateResolvConf = true;
        servers = [
          {
            address = "146.70.174.194";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "146.70.202.66";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "149.102.224.162";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "149.22.94.28";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "149.36.48.141";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "149.40.49.30";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "149.88.18.193";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "185.156.46.33";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "217.138.198.246";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "37.19.200.27";
            ports = [ 51820 5060 80 4569 1194 ];
          }
          {
            address = "45.134.140.59";
            ports = [ 51820 5060 80 4569 1194 ];
          }
        ];
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
