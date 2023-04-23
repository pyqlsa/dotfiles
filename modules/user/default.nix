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
      description = "common user configurations";
      default = true;
    };
  };

  config = mkIf (cfg.user.enable) {
    programs.zsh.enable = true;

    users.defaultUserShell = pkgs.zsh;

    environment.systemPackages = with pkgs; [
      zsh
    ];

    environment.shells = with pkgs; [
      zsh
    ];

    # to enable completion from system packages
    environment.pathsToLink = [ "/share/zsh" ];

    users.users.pyqlsa = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "networkmanager" ]; # Enable ‘sudo’ for the user.
      initialHashedPassword = "$6$HOEpMO//XbnyqggK$j7M1ZRhwPsUKW4thZofEpo6aY6gteZ99hNFrRPEmlH6Lh3afQUBckvnQ/N8MtdVdP/jIHRa1KMuq3PCJsZmKe.";
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGrK3R3Yo3uBAORs2QFfERsvQh/D6n3f5Em3cvrnr/N pyqlsa" ];
      shell = pkgs.zsh;
    };
  };
}
