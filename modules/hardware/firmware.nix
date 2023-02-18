{ pkgs
, config
, lib
, ...
}: {
  config = {
    # Enable all unfree hardware support.
    hardware.firmware = with pkgs; [ firmwareLinuxNonfree ];
    hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;

    # Enable firmware update service
    services.fwupd.enable = true;

    # from nix hardware configuration, common-pc
    boot.blacklistedKernelModules = lib.optionals (!config.hardware.enableRedistributableFirmware) [
      "ath3k"
    ];
  };
}
