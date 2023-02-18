{ pkgs
, config
, lib
, ...
}:
with lib; let
  cfg = config.sys;
in
{
  options.sys = {
    locale = mkOption {
      type = types.str;
      description = "The locale for the machine";
      default = "en_US.UTF-8";
    };

    keyMap = mkOption {
      type = types.str;
      description = "The keyboard mapping table for the machine (virtual consoles)";
      default = "us";
    };

    timeZone = mkOption {
      type = types.str;
      description = "The timezone of the machine";
      default = "America/Los_Angeles";
    };
  };

  config = {
    i18n.defaultLocale = cfg.locale;
    console.keyMap = cfg.keyMap;
    time.timeZone = cfg.timeZone;
  };
}
