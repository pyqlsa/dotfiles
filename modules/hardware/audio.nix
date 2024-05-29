{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib;
with builtins; let
  cfg = config.sys;
in
{
  options.sys.hardware.audio.server = mkOption {
    type = types.enum [ "pulse" "pipewire" "none" ];
    default = "none";
    description = "Audio server to use";
  };

  config = mkIf (cfg.hardware.audio.server != "none") {
    sys.software = [
      # Need pulseaudio cli tools for pipewire.
      (mkIf (cfg.hardware.audio.server == "pipewire") pulseaudio)
      pulsemixer
    ];

    sound.enable = cfg.hardware.audio.server == "pulse";
    security.rtkit.enable = true;

    services.pipewire = mkIf (cfg.hardware.audio.server == "pipewire") {
      enable = true;
      audio.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    hardware.pulseaudio = mkIf (cfg.hardware.audio.server == "pulse") {
      enable = true;
      support32Bit = true;
      package = pulseaudioFull;
    };
  };
}
