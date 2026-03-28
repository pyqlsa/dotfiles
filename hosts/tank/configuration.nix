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
  sops.secrets."namecheap/secretVals" = {
    sopsFile = ../../secrets/apps/namecheap.yaml;
  };
  sops.secrets."tailscale/authKey" = {
    sopsFile = ../../secrets/hosts/tank.yaml;
  };
  sops.secrets."tailscale/authEnv" = {
    sopsFile = ../../secrets/hosts/tank.yaml;
    owner = config.sys.tailscale.caddy.user;
  };

  # custom modules
  sys.security.sshd.enable = true;

  sys.hardware.amd.enable = true;

  sys.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/authKey".path;
    caddy = {
      enable = true;
      envFiles = [ config.sops.secrets."tailscale/authEnv".path ];
      globalConfig = ''
        servers {
          timeouts {
            read_body 300s
            read_header 300s
            write 300s
            idle 300s
          }
        }
      '';
      virtualHosts = {
        "tank.bleak-shaula.ts.net" = {
          extraConfig = ''
            redir /media /media/

            handle / {
              respond "hello from tailnet; your ip is {client_ip}" 200
            }

            handle /media/* {
              reverse_proxy /media/* http://127.0.0.1:8096
            }

            handle {
              respond "404 Not Found" 404
            }
          '';
        };
        "localhost" = {
          extraConfig = ''
            handle / {
              respond "hello from local; your ip is {client_ip}" 200
            }

            handle {
              respond "404 Not Found" 404
            }
          '';
        };
      };
    };
  };

  sys.software = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "23.11";
}
