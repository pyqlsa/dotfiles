{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys.tailscale;

  caddyCfg = { config, options, ... }: {
    options = {
      enable = mkEnableOption (lib.mdDoc "enable caddy as a reverse proxy");
      user = mkOption {
        type = types.str;
        description = "user to run caddy as";
        default = "caddy";
        example = "other-caddy";
      };
      group = mkOption {
        type = types.str;
        description = "group to run caddy as";
        default = "caddy";
        example = "other-caddy";
      };
      acmeVarFile = mkOption {
        type = with types; nullOr str;
        description = "environment variable file with dns provide api credentials";
        default = null;
        example = "/path/to/envfile";
      };
      envFiles = mkOption {
        type = with types; (listOf str);
        description = "environment variable files";
        default = [ ];
        example = [ "/path/to/envfile" ];
      };
      globalConfig = mkOption {
        type = with types; str;
        description = "global configuration options to pass through";
        default = "";
      };
      virtualHosts = mkOption {
        type = with types; attrs;
        description = "direct passthrough to `services.caddy.virtualHosts`";
        default = { };
        example = {
          "localhost" = {
            extraconfig = "respond 'foo'";
          };
        };
      };
    };
  };
in
{
  options.sys.tailscale = {
    enable = mkEnableOption (lib.mddoc "enable tailscale");
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr (lib.types.path);
      default = null;
      description = "file where a tailnet auth key is stored";
    };
    caddy = mkOption {
      type = types.submodule caddyCfg;
      default = { enable = false; user = "caddy"; virtualHosts = [ ]; };
      example = { enable = false; user = "caddy"; virtualHosts = [ ]; };
      description = "caddy reverse proxy configuration block.";
    };
  };

  config = lib.mkIf (cfg.enable) {
    services.tailscale = {
      enable = true;
      port = 41641;
      openFirewall = false; # done elsewhere

      useRoutingFeatures = "none";
      disableUpstreamLogging = true;
      disableTaildrop = false;

      extraSetFlags = [ ]; # "--ssh"
      extraDaemonFlags = [ ];
      permitCertUid = lib.mkIf (cfg.caddy.enable) cfg.caddy.user;

      authKeyFile = cfg.authKeyFile;
      authKeyParameters = { };
      extraUpFlags = [ ];

      derper = {
        enable = false;
        domain = ""; # needed when in use
        port = 8010;
        stunPort = 3478;
        openFirewall = false; # only when used
        verifyClients = true; # non default
        configureNginx = false; # non default
      };
    };

    services.caddy = lib.mkIf (cfg.caddy.enable) {
      enable = true;
      user = cfg.caddy.user;
      group = cfg.caddy.group;
      package = pkgs.caddy.withPlugins {
        plugins = [
          #"github.com/caddy-dns/namecheap@v1.0.0"
          "github.com/tailscale/caddy-tailscale@v0.0.0-20260106222316-bb080c4414ac"
        ];
        hash = "sha256-xJOPVE56h4tlhW7m8ZFN8F2jrZW/3gYeLXVqaEaoVvY=";
      };
      virtualHosts = cfg.caddy.virtualHosts;
      globalConfig = cfg.caddy.globalConfig;
      #globalConfig = lib.mkIf cfg.caddy.acmeVarFile != null ''
      #  acme_dns namecheap {
      #    api_key {env.namecheap_api_key}
      #    user {env.namecheap_api_user}
      #    api_endpoint https://api.namecheap.com/xml.response
      #    client_ip {env.namecheap_client_ip}
      #  }
      #'';
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile = lib.mkIf (cfg.caddy.enable) cfg.caddy.envFiles;
    #++ (if (cfg.caddy.acmeVarFile != null) then [ cfg.caddy.acmeVarFile ] else [ ]);

    networking.nftables.enable = true;
    networking.firewall = {
      enable = true;
      # Always allow traffic from your Tailscale network
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
      # Allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    # 2. Force tailscaled to use nftables (Critical for clean nftables-only systems)
    # This avoids the "iptables-compat" translation layer issues.
    systemd.services.tailscaled.serviceConfig.Environment = [
      "TS_DEBUG_FIREWALL_MODE=nftables"
    ];

    # 3. Optimization: Prevent systemd from waiting for network online
    # (Optional but recommended for faster boot with VPNs)
    systemd.network.wait-online.enable = lib.mkDefault false;
    boot.initrd.systemd.network.wait-online.enable = lib.mkDefault false;
  };
}
