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
  sops.secrets."protonvpn/creds" = {
    sopsFile = ../../secrets/apps/protonvpn.yaml;
  };
  sops.secrets."protonvpn/certificate" = {
    sopsFile = ../../secrets/apps/protonvpn.yaml;
  };
  sops.secrets."protonvpn/key" = {
    sopsFile = ../../secrets/apps/protonvpn.yaml;
  };
  sops.secrets."searxng/secretVals" = {
    sopsFile = ../../secrets/apps/searxng.yaml;
  };
  sops.secrets."tailscale/authKey" = {
    sopsFile = ../../secrets/hosts/wilderness.yaml;
  };
  sops.secrets."tailscale/authEnv" = {
    sopsFile = ../../secrets/hosts/wilderness.yaml;
    owner = config.sys.tailscale.caddy.user;
  };

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
    allowAllOrigins = true;
    modelService = {
      enable = true;
    };
    web = {
      enable = true;
      modelServiceUrl = "http://${config.sys.llm.modelService.host}:${lib.toString config.sys.llm.modelService.port}";
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

  sys.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/authKey".path;
    caddy = {
      enable = true;
      envFiles = [ config.sops.secrets."tailscale/authEnv".path ];
      globalConfig = ''
        debug
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
        "wilderness.bleak-shaula.ts.net" = {
          extraConfig = ''
            respond "hello from tailnet; your ip is {client_ip}"
          '';
        };
        "https://llm.bleak-shaula.ts.net" = {
          extraConfig = ''
            bind tailscale/llm
            reverse_proxy ${config.sys.llm.modelService.host}:${builtins.toString config.sys.llm.modelService.port} {
              header_up Host {upstream_hostport}
              header_up Origin {upstream_hostport}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {http.request.host}
              header_up X-Forwarded-Proto {http.request.scheme}
              header_up X-Forwarded-Port {http.request.port}
              header_up Upgrade {http.request.header.Upgrade}
              header_up Connection {http.request.header.Connection}

              flush_interval -1
            }
          '';
        };
        "https://owui.bleak-shaula.ts.net" = {
          extraConfig = ''
            @cors_preflight method OPTIONS
            handle @cors_preflight {
              header Access-Control-Allow-Origin "*"
              header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
              header Access-Control-Allow-Headers "*"
              header Access-Control-Max-Age "3600"
              respond "" 204
            }
            bind tailscale/owui
            reverse_proxy ${config.sys.llm.web.host}:${builtins.toString config.sys.llm.web.port} {
              header_down Access-Control-Allow-Origin "*"
              header_up Host {upstream_hostport}
              header_up Origin {upstream_hostport}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {http.request.host}
              header_up X-Forwarded-Proto {http.request.scheme}
              header_up X-Forwarded-Port {http.request.port}
              header_up Upgrade {http.request.header.Upgrade}
              header_up Connection {http.request.header.Connection}
              #header_up Sec-WebSocket-Extensions {http.request.header.Sec-WebSocket-Extensions}

              flush_interval -1
            }
          '';
        };
        "https://cui.bleak-shaula.ts.net" = {
          extraConfig = ''
            bind tailscale/cui
            reverse_proxy ${config.sys.llm.comfy.host}:${builtins.toString config.sys.llm.comfy.port} {
              header_down X-Real-IP {http.request.remote}
              header_down X-Forwarded-For {http.request.remote}
            }
          '';
        };
        "https://srx.bleak-shaula.ts.net" = {
          extraConfig = ''
            bind tailscale/srx
            reverse_proxy ${config.sys.llm.searxng.host}:${builtins.toString config.sys.llm.searxng.port} {
              header_down X-Real-IP {http.request.remote}
              header_down X-Forwarded-For {http.request.remote}
            }
          '';
        };
        "localhost" = {
          extraConfig = ''
            respond "hello from local; your ip is {client_ip}"
          '';
        };
      };
    };
  };

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
        openvpnCreds = config.sops.secrets."protonvpn/creds".path;
        openvpnCertificate = config.sops.secrets."protonvpn/certificate".path;
        openvpnKey = config.sops.secrets."protonvpn/key".path;
      };
    in
    {
      proton-strict = {
        autostart = false;
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "22.11";
}
