{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys;

  comfyGpu =
    if cfg.llm.shared.gpu-type == "auto" then
      if cfg.hardware.amd.enable then
        "rocm"
      else
        if cfg.hardware.nvidia.enable then
          "cuda"
        else
          "none"
    else
      if cfg.llm.shared.gpu-type == "amd" then
        "rocm"
      else
        if cfg.llm.shared.gpu-type == "nvidia" then
          "cuda"
        else
          if cfg.llm.shared.gpu-type == "vulkan" then
            "none" # TODO: dunno what we should do here
          else
            if cfg.llm.shared.gpu-type == "none" then
              "none"
            else
              "none"
  ;
in
{
  options.sys.llm.comfy = {
    enable = mkEnableOption (lib.mdDoc "enable comfy-ui");
    host = mkOption {
      type = with types; str;
      description = "host for the comfy-ui service";
      default = "127.0.0.1";
      example = "0.0.0.0";
    };
    port = mkOption {
      type = with types; port;
      description = "port number for the comfy-ui service";
      default = 8188;
      example = 11111;
    };
    openFirewall = mkEnableOption (lib.mdDoc "open the firewall for the comfy-ui interface");
    gpuSupport = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "cuda" "rocm" "none" ]);
      default = null;
      description = "passthrough `gpuSupport` setting to comfyui, bypassing auto-selection";
    };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra CLI arguments passed to ComfyUI.";
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables for the ComfyUI service.";
    };
  };

  config = lib.mkIf (cfg.llm.comfy.enable) {
    # from comfyui-nix flake
    services.comfyui = {
      enable = true;
      gpuSupport = if cfg.llm.comfy.gpuSupport == null then comfyGpu else cfg.llm.comfy.gpuSupport;
      enableManager = false;
      listenAddress = cfg.llm.comfy.host;
      port = cfg.llm.comfy.port;
      openFirewall = cfg.llm.comfy.openFirewall;
      extraArgs = cfg.llm.comfy.extraArgs;
      environment = cfg.llm.comfy.environment;
    };

    nix.settings = {
      trusted-substituters = [
        # for comfyui-nix
        "https://comfyui.cachix.org"
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-public-keys = [
        # for comfyui-nix
        "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };
}

