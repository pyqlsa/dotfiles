{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys;

  webCfg = { config, options, ... }: {
    options = {
      enable = mkEnableOption (lib.mdDoc "enable the web interface");
      host = mkOption {
        type = types.str;
        description = "host for the web service";
        default = "127.0.0.1";
        example = "0.0.0.0";
      };
      port = mkOption {
        type = types.number;
        description = "port number for the web service";
        default = 8080;
        example = 11111;
      };
      openFirewall = mkEnableOption (lib.mdDoc "open the firewall for the web interface");
    };
  };
  ollamaPkg =
    if cfg.llm.gpu-type == "auto" then
      if cfg.hardware.amd.enable then
        pkgs.ollama-rocm
      else
        if cfg.hardware.nvidia.enable then
          pkgs.ollama-cuda
        else
          pkgs.ollama-cpu
    else
      if cfg.llm.gpu-type == "amd" then
        pkgs.ollama-rocm
      else
        if cfg.llm.gpu-type == "nvidia" then
          pkgs.ollama-cuda
        else
          if cfg.llmg.gpu-type == "vulkan" then
            pkgs.ollama-vulkan
          else
            if cfg.llmg.gpu-type == "none" then
              pkgs.ollama-cpu
            else
              pkgs.ollama
  ;
in
{
  options.sys.llm = {
    enable = mkEnableOption (lib.mdDoc "enable an opinionated local llm install and configuration");
    host = mkOption {
      type = types.str;
      description = "host for the llm service";
      default = "127.0.0.1";
      example = "0.0.0.0";
    };
    port = mkOption {
      type = types.number;
      description = "port number for the llm service";
      default = 11434;
      example = 11111;
    };
    openFirewall = mkEnableOption (lib.mdDoc "open the firewall for the llm service");
    web = mkOption {
      type = types.submodule webCfg;
      default = { enable = false; host = "127.0.0.1"; port = 8080; openFirewall = false; };
      example = { enable = false; host = "127.0.0.1"; port = 8080; openFirewall = false; };
      description = "web configuration block.";
    };
    gpu-type = mkOption {
      type = types.enum [ "amd" "nvidia" "vulkan" "none" "auto" ];
      default = "auto";
      description = "indicator for library/package compat.";
    };

  };

  config = lib.mkIf (cfg.llm.enable) {
    services.ollama = {
      enable = true;
      package = ollamaPkg;
      host = cfg.llm.host;
      port = cfg.llm.port;
      openFirewall = false;
      user = "ollama";
      group = "ollama";
      home = "/var/lib/ollama";
      models = "${config.services.ollama.home}/models";
      loadModels = [ ];
      syncModels = false;
      environmentVariables = { };
    };

    sys.software = with pkgs; [
      oterm
    ];

    services.open-webui = lib.mkIf (cfg.llm.web.enable) {
      enable = true;
      host = cfg.llm.web.host;
      port = cfg.llm.web.port;
      openFirewall = false;
      stateDir = "/var/lib/open-webui";
      environmentFile = null;
      # https://docs.openwebui.com/getting-started/env-configuration
      environment = {
        # ...
        ENABLE_PERSISTENT_CONFIG = "True";
        # ...
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        # ...
        WEBUI_AUTH = "True";
        ENABLE_SIGNUP = "True";
        ENABLE_SIGNUP_PASSWORD_CONFIRMATION = "True";
        # ...
        GLOBAL_LOG_LEVEL = "INFO";
        # ...
        OLLAMA_BASE_URL = "http://${cfg.llm.host}:${toString cfg.llm.port}";
      };
    };
  };
}
