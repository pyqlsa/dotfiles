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

  # try to get keyboard brightnessctl working
  boot.blacklistedKernelModules = [ "hid_sensor_hub" ];

  networking.hostName = "fmwk-7850u";
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # --- power
  boot.kernelParams = [ "amd_pstate=active" ];

  # fingerprint reader; TODO still broken
  services.fprintd.enable = true;

  # while framework matures their lvfs support
  services.fwupd.extraRemotes = [ "lvfs-testing" ];
  # we need fwupd 1.9.7 to downgrade the fingerprint sensor firmware
  #services.fwupd.package = (import
  #  (builtins.fetchTarball {
  #    url = "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
  #    sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
  #  })
  #  {
  #    inherit (pkgs) system;
  #  }).fwupd;

  # allow to build some arm things
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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
          pointer_accel 0.3 # set mouse sensitivity (between -1 and 1)
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
  # audio stuff
  #boot.extraModprobeConfig = ''
  #  options snd-hda-intel index=1,0 model=auto,dell-headset-multi
  #'';
  #boot.extraModprobeConfig = ''
  #  options snd-hda-intel model=dell-headset-multi
  #'';

  sys.security.sshd.enable = true;

  sys.virtualisation.virt-manager.enable = true;

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
        autostart = true;
      } // commonOpts;
      proton-allow-local = {
        autostart = false;
        localNets = [
          { net = "10.10.0.0"; mask = "255.255.0.0"; }
          { net = "10.5.0.0"; mask = "255.255.0.0"; }
          { net = "10.200.0.0"; mask = "255.255.0.0"; }
          { net = "10.0.0.0"; mask = "255.255.0.0"; }
        ];
        extraDns = [ "10.10.1.1" ];
      } // commonOpts;
    };

  system.stateVersion = "23.11";
}
