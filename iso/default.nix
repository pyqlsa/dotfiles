{config, pkgs, ...}:
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    nvme-cli
    smartmontools
    git
    gh
    vim
    neovimPQ
  ];
}
