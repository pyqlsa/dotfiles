{ pkgs
, config
, lib
, ...
}: {
  sys.software = with pkgs; [
    acpi
    btrfs-progs
    cryptsetup
    dmidecode
    exfat
    hwdata
    iotop
    lm_sensors
    #ntfsprogs
    nvme-cli
    pciutils
    smartmontools
    usbutils
  ];
}
