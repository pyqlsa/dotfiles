{ config
, lib
, pkgs
, ...
}: {
  sys.software = with pkgs; [
    config.boot.kernelPackages.perf
    bind
    file
    lshw
    openssl
    screen
    tmux
    tree
    squashfsTools
  ];
}
