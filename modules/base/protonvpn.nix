# based on: https://github.com/emmanuelrosa/erosanix/blob/3741f6fab6e5667689c48828e46379282ec33966/modules/protonvpn.nix
{ config
, lib
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options = {
    sys.protonvpn = {
      enable = mkEnableOption "Enable ProtonVPN (using Wireguard).";

      autostart = mkOption {
        default = true;
        example = "true";
        type = types.bool;
        description = "Automatically set up ProtonVPN when NixOS boots.";
      };

      updateResolvConf = mkOption {
        default = true;
        example = "true";
        type = types.bool;
        description = "Use update-resolv-conf package to auto-update resolv.conf with DNS information provided by openvpn.";
      };

      server = mkOption {
        type = types.str;
        default = "us-free-01.protonvpn.com";
        example = "us-free-01.protonvpn.com";
        description = "The ProtonVPN server to use. You can choose a server from the lists provided here: `https://account.protonmail.com/u/0/vpn/open-vpn-ike-v2`";
      };

      protocol = mkOption {
        type = types.enum [ "udp" "tcp" ];
        default = "udp";
        example = "tcp";
        description = "The network protocol to use for the VPN connection. See `https://protonvpn.com/support/udp-tcp/`";
      };

      openvpnCreds = mkOption {
        default = "";
        example = ''`config.sops.secrets."vpn/protonvpn/creds".path`'';
        type = types.path;
        description = "Path to openvpn credential file.";
      };

      openvpnCertificate = mkOption {
        default = "";
        example = ''`config.sops.secrets."vpn/protonvpn/certificate".path`'';
        type = types.path;
        description = "Path to openvpn CA certificate file.";
      };

      openvpnKey = mkOption {
        default = "";
        example = ''`config.sops.secrets."vpn/protonvpn/key".path`'';
        type = types.path;
        description = "Path to openvpn tls-crypt key file.";
      };
    };
  };

  config = mkIf cfg.protonvpn.enable {
    services.openvpn.servers.proton = {
      autoStart = cfg.protonvpn.autostart;
      updateResolvConf = cfg.protonvpn.updateResolvConf;
      config = ''
        # The server you are connecting to is using a circuit in order to separate entry IP from exit IP
        # The same entry IP allows to connect to multiple exit IPs in the same data center.

        # If you want to explicitly select the exit IP corresponding to server <server> you need to
        # append a special suffix to your OpenVPN username.
        # Please use "<username>+b:6" in order to enforce exiting through <server>.

        # If you are a paying user you can also enable the ProtonVPN ad blocker (NetShield) or Moderate NAT:
        # Use: "<username>+b:6+f1" to enable anti-malware filtering
        # Use: "<username>+b:6+f2" to additionally enable ad-blocking filtering
        # Use: "<username>+b:6+nr" to enable Moderate NAT
        # Note that you can combine the "+nr" suffix with other suffixes.

        client
        dev tun
        proto ${cfg.protonvpn.protocol}

        remote ${cfg.protonvpn.server} 51820
        remote ${cfg.protonvpn.server} 5060
        remote ${cfg.protonvpn.server} 80
        remote ${cfg.protonvpn.server} 4569
        remote ${cfg.protonvpn.server} 1194

        remote-random
        resolv-retry infinite
        nobind

        cipher AES-256-GCM

        setenv CLIENT_CERT 0
        tun-mtu 1500
        mssfix 0
        persist-key
        persist-tun

        reneg-sec 0

        remote-cert-tls server

        auth-user-pass ${cfg.protonvpn.openvpnCreds}

        script-security 2

        ca ${cfg.protonvpn.openvpnCertificate}

        tls-crypt ${cfg.protonvpn.openvpnKey}
      '';
    };
  };
}
