{ config
, lib
, pkgs
, ...
}: {
  sys.software = with pkgs; [
    openssl
    squashfsTools
  ];
}
