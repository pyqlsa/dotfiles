{ config
, lib
, pkgs
, ...
}: {
  sys.software = with pkgs; [
    bind
    file
    lshw
    openssl
    screen
    tmux
    squashfsTools
  ];
}
