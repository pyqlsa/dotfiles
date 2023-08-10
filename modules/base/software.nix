{ config
, lib
, pkgs
, ...
}: {
  sys.software = with pkgs; [
    file
    openssl
    squashfsTools
  ];
}
