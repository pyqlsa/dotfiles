{ config
, lib
, pkgs
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys;
in
{
  # shared across all submodules
  options.sys.llm.shared = {
    enable-llm-agents = mkEnableOption (lib.mdDoc "enable cache keys for llm-agents");
    gpu-type = mkOption {
      type = types.enum [ "amd" "nvidia" "vulkan" "none" "auto" ];
      default = "auto";
      description = "indicator for library/package compat.";
    };
  };

  config = lib.mkIf (cfg.llm.shared.enable-llm-agents) {
    nix.settings = {
      trusted-substituters = [
        # for llm-agents.nix
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        # for llm-agents.nix
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
  };
}
