{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys.user = {
    enable = mkOption {
      type = types.bool;
      description = "common configurations for users";
      default = true;
    };

    zshDefault = mkOption {
      type = types.bool;
      description = "set zsh as the default shell for all users";
      default = true;
    };

    name = mkOption {
      type = types.str;
      description = "username to set for the primary login user";
      default = "pyqlsa";
    };

    gitUsername = mkOption {
      type = types.str;
      description = "username to use in git config";
      default = cfg.user.name;
    };

    gitEmail = mkOption {
      type = types.str;
      description = "email to use in git config";
      default = "26353308+pyqlsa@users.noreply.github.com";
    };

    sshKeys = mkOption {
      type = with types; listOf str;
      description = "ssh authorized keys for the primary login user";
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGrK3R3Yo3uBAORs2QFfERsvQh/D6n3f5Em3cvrnr/N pyqlsa"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJtSB0+FKOQneFprWC/uXbnw2zMAxMrpQ6SsX4w1A7/ pyqlsa"
      ];
    };
  };

  config = mkIf (cfg.user.enable) {
    programs.zsh.enable = cfg.user.zshDefault;

    users.defaultUserShell = pkgs.zsh;

    environment.systemPackages =
      if cfg.user.zshDefault
      then with pkgs; [ zsh ]
      else [ ];

    environment.shells =
      if cfg.user.zshDefault
      then with pkgs; [ zsh ]
      else [ ];

    # to enable completion from system packages
    environment.pathsToLink =
      if cfg.user.zshDefault
      then [ "/share/zsh" ]
      else [ ];

    users.users."${cfg.user.name}" = {
      isNormalUser = true;
      createHome = true;
      home = "/home/${cfg.user.name}";
      extraGroups =
        [ "wheel" "video" "networkmanager" "kvm" ]
        ++ (
          if cfg.virtualisation.virt-manager.enable
          then [ "libvirtd" ]
          else [ ]
        )
        ++ (
          if config.programs.adb.enable == true
          then [ "adbusers" ]
          else [ ]
        );
      initialHashedPassword = "$6$HOEpMO//XbnyqggK$j7M1ZRhwPsUKW4thZofEpo6aY6gteZ99hNFrRPEmlH6Lh3afQUBckvnQ/N8MtdVdP/jIHRa1KMuq3PCJsZmKe.";
      openssh.authorizedKeys.keys = cfg.user.sshKeys;
      shell = pkgs.zsh;
    };
  };
}
