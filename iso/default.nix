{ config
, pkgs
, ...
}: {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [
    nvme-cli
    smartmontools
    git
    gh
    vim
    neovimPQ
  ];
}
