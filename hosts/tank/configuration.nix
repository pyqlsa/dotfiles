{ config
, lib
, pkgs
, ...
}: {
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zfs
  boot.supportedFilesystems = [ "btrfs" "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
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
    useDHCP = lib.mkDefault true;
    #useDHCP = false;
    #interfaces = {
    #  enp10s0f0np0 = {
    #    useDHCP = false;
    #    ipv4.addresses = [
    #      {
    #        address = "10.10.1.50";
    #        prefixLength = 24;
    #      }
    #    ];
    #  };
    #};
    #defaultGateway = "10.10.1.1";
    #nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };

  # networking.interfaces.enp10s0f0np0.useDHCP = lib.mkDefault true;
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
    # helpers for media serveer
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    serverTokens = false;
    clientMaxBodySize = "20m";
    sslProtocols = "TLSv1.2 TLSv1.3";
    appendHttpConfig = ''
        # TODO: size limits and buffer overflows
        #client_body_buffer_size 256k;
        #client_header_buffer_size 32k;
        #large_client_header_bufers 8 32kk;
        #client_max_body_size 20m;

        # Security / XSS Mitigation Headers
        # NOTE: X-Frame-Options may cause issues with the webOS app
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-XSS-Protection "0"; # Do NOT enable. This is obsolete/dangerous
        add_header X-Content-Type-Options "nosniff";

        # COOP/COEP. Disable if you use external plugins/images/assets
        add_header Cross-Origin-Opener-Policy "same-origin" always;
        add_header Cross-Origin-Embedder-Policy "require-corp" always;
        add_header Cross-Origin-Resource-Policy "same-origin" always;

        # Permissions policy. May cause issues on some clients
        add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;

        # Tell browsers to use per-origin process isolation
        add_header Origin-Agent-Cluster "?1" always;
      #'';

    # media server
    virtualHosts."${config.networking.hostName}.${config.networking.domain}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        extraConfig = ''
          deny all;
        '';
      };
      locations."/media" = {
        extraConfig = ''
          return 302 $scheme://$host/media/;
        '';
      };
      locations."/media/" = {
        proxyPass = "http://127.0.0.1:8096/media/";
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "26353308+pyqlsa@users.noreply.github.com";
    defaults.group = "nginx";
    certs."${config.networking.hostName}.${config.networking.domain}" = {
      dnsProvider = "namecheap";
      environmentFile = config.sops.secrets."api/dns".path;
      dnsPropagationCheck = true;
      webroot = null;
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "23.11";
}
