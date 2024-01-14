{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys.security;
in
{
  options.sys.security = {
    sshd = {
      enable = mkEnableOption (lib.mdDoc "Enable sshd service on system");

      port = mkOption {
        type = types.int;
        description = "Port to use for ssh daemon";
        default = 22;
      };
    };
  };

  config = {
    # primarily to aid in remote building and switching
    security.pam.enableSSHAgentAuth = true;
    # Stops sudo from timing out.
    #security.sudo.extraConfig = "Defaults env_reset,timestamp_timeout=-1";
    security.sudo = {
      enable = true;
      execWheelOnly = true;
    };

    services.openssh = {
      enable = cfg.sshd.enable;
      ports = [ cfg.sshd.port ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
      # this or configure firewall directly?
      #openFirewall = cfg.sshd.enable;
      banner = ''
                  /\
                 /**\
                /****\   /\
               /      \ /**\
              /  /\    /    \        /\    /\  /\      /\            /\/\/\  /\
             /  /  \  /      \      /  \/\/  \/  \  /\/  \/\  /\  /\/ / /  \/  \
            /  /    \/ /\     \    /    \ \  /    \/ /   /  \/  \/  \  /    \   \
           /  /      \/  \/\   \  /      \    /   /    \
        __/__/_______/___/__\___\__________________________________________________
      '';
    };
    networking.firewall.allowedTCPPorts = [ (mkIf (cfg.sshd.enable) cfg.sshd.port) ];
    networking.firewall.allowPing = false;
  };
}
