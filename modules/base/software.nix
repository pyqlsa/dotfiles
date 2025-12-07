{ config
, lib
, pkgs
, ...
}: {
  sys.software = with pkgs; [
    perf
    bind
    file
    lshw
    openssl
    parted
    tmux
    tree
    squashfsTools
    strace
  ];
}
