{ config
, lib
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.ns = {
    enable = mkOption {
      type = types.bool;
      description = "opinionated nameservers";
      default = true;
    };
  };

  config = mkIf (cfg.ns.enable) {
    networking = {
      nameservers = [ "1.1.1.1" "1.0.0.1" ];
      #dhcpcd.extraConfig = "nohook resolv.conf";
      #networkmanager.dns = "none";
    };
    #services.resolved.enable = false;
  };
}
