{ config
, lib
, pkgs
, ...
}: {
  sys.software = with pkgs; [
    file
    lshw
    openssl
    screen
    squashfsTools
  ];
}
