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
    domain = "nochtlabs.net";
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

  sops.defaultSopsFile = ../../secrets/default.yaml;
  sops.defaultSopsFormat = "yaml";
  # This will automatically import SSH keys as gpg keys
  sops.gnupg.sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
  # actual secrets
  sops.secrets."api/dns" = { };

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
    openFirewall = false;
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."media.tank.nochtlabs.net" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "26353308+pyqlsa@users.noreply.github.com";
    defaults.group = "nginx";
    certs."media.tank.nochtlabs.net" = {
      dnsProvider = "namecheap";
      environmentFile = config.sops.secrets."api/dns".path;
      dnsPropagationCheck = true;
      webroot = null;
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "23.11";
}
