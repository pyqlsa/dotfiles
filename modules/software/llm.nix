{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys;

  modelServiceCfg = { config, options, ... }: {
    options = {
      enable = mkEnableOption (lib.mdDoc "enable the model service");
      host = mkOption {
        type = with types; str;
        description = "host for the model service";
        default = "127.0.0.1";
        example = "0.0.0.0";
      };
      port = mkOption {
        type = with types; port;
        description = "port number for the model service";
        default = 8080;
        example = 11343;
      };
      openFirewall = mkEnableOption (lib.mdDoc "open the firewall for the model service");
      modelsDir = mkOption {
        type = with types; str;
        description = "directory for model files";
        default = "/var/lib/llama/models";
        example = "/var/lib/llama/models/cache";
      };
      modelsUser = mkOption {
        type = with types; str;
        description = "user to own models dir";
        example = "root";
      };
      modelsGroup = mkOption {
        type = with types; str;
        description = "group to own models dir";
        default = "users";
        example = "root";
      };
    };
  };

  webCfg = { config, options, ... }: {
    options = {
      enable = mkEnableOption (lib.mdDoc "enable the web interface");
      host = mkOption {
        type = with types; str;
        description = "host for the web service";
        default = "127.0.0.1";
        example = "0.0.0.0";
      };
      port = mkOption {
        type = with types; port;
        description = "port number for the web service";
        default = 8088;
        example = 11111;
      };
      openFirewall = mkEnableOption (lib.mdDoc "open the firewall for the web interface");
      modelServiceUrl = mkOption {
        type = with types; str;
        description = "url for the language model service to use";
        default = "http://${cfg.llm.modelService.host}:${toString cfg.llm.modelService.host}";
        example = "https://example.com";
      };
    };
  };

  comfyCfg = { config, options, ... }: {
    options = {
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
  };

  searxngCfg = { config, options, ... }: {
    options = {
      enable = mkEnableOption (lib.mdDoc "enable searxng");
      host = mkOption {
        type = with types; str;
        description = "host for the searxng service";
        default = "127.0.0.1";
        example = "0.0.0.0";
      };
      port = mkOption {
        type = with types; port;
        description = "port number for the searxng service";
        default = 8888;
        example = 11111;
      };
      openFirewall = mkEnableOption (lib.mdDoc "open the firewall for the searxng interface");
      environmentFile = lib.mkOption {
        type = lib.types.nullOr (lib.types.path);
        default = null;
        description = "environment variable file for searxng";
      };
    };
  };

  llamaPkg =
    if cfg.llm.gpu-type == "auto" then
      if cfg.hardware.amd.enable then
        pkgs.llama-cpp.override { rocmSupport = true; }
      else
        if cfg.hardware.nvidia.enable then
          pkgs.llama-cpp.override { cudaSupport = true; }
        else
          pkgs.llama-cpp
    else
      if cfg.llm.gpu-type == "amd" then
        pkgs.llama-cpp.override { rocmSupport = true; }
      else
        if cfg.llm.gpu-type == "nvidia" then
          pkgs.llama-cpp.override { cudaSupport = true; }
        else
          if cfg.llm.gpu-type == "vulkan" then
            pkgs.llama-cpp.override { vulkanSupport = true; }
          else
            if cfg.llm.gpu-type == "none" then
              pkgs.llama-cpp
            else
              pkgs.llama-cpp
  ;

  comfyGpu =
    if cfg.llm.gpu-type == "auto" then
      if cfg.hardware.amd.enable then
        "rocm"
      else
        if cfg.hardware.nvidia.enable then
          "cuda"
        else
          "none"
    else
      if cfg.llm.gpu-type == "amd" then
        "rocm"
      else
        if cfg.llm.gpu-type == "nvidia" then
          "cuda"
        else
          if cfg.llm.gpu-type == "vulkan" then
            "none" # TODO: dunno what we should do here
          else
            if cfg.llm.gpu-type == "none" then
              "none"
            else
              "none"
  ;
in
{
  options.sys.llm = {
    enable = mkEnableOption (lib.mdDoc "enable an opinionated local llm related configuration");
    modelService = mkOption {
      type = types.submodule modelServiceCfg;
      default = { enable = false; host = "127.0.0.1"; port = 8080; openFirewall = false; };
      example = { enable = true; host = "127.0.0.1"; port = 8080; openFirewall = false; };
      description = "web configuration block.";
    };
    web = mkOption {
      type = types.submodule webCfg;
      default = { enable = false; host = "127.0.0.1"; port = 8088; openFirewall = false; };
      example = { enable = true; host = "127.0.0.1"; port = 8088; openFirewall = false; };
      description = "web configuration block.";
    };
    comfy = mkOption {
      type = types.submodule comfyCfg;
      default = { enable = false; host = "127.0.0.1"; port = 8188; openFirewall = false; };
      example = { enable = true; host = "127.0.0.1"; port = 8188; openFirewall = false; };
      description = "web configuration block.";
    };
    searxng = mkOption {
      type = types.submodule searxngCfg;
      default = { enable = false; host = "127.0.0.1"; port = 8888; openFirewall = false; };
      example = { enable = true; host = "127.0.0.1"; port = 8888; openFirewall = false; };
      description = "searxng configuration block.";
    };
    extraAllowedOrigins = mkOption {
      type = with types; listOf str;
      description = "extra allowed origins for CORS";
      default = [ ];
    };
    allowAllOrigins = mkOption {
      type = with types; bool;
      description = "configure CORS allowed orgins as '*'";
      default = false;
    };
    gpu-type = mkOption {
      type = types.enum [ "amd" "nvidia" "vulkan" "none" "auto" ];
      default = "auto";
      description = "indicator for library/package compat.";
    };
  };

  config = lib.mkIf (cfg.llm.enable) {
    sys.llm.modelService.modelsUser = lib.mkDefault "${config.sys.user.name}";

    services.llama-swap =
      let
        llama-server = "${llamaPkg}/bin/llama-server";
      in
      lib.mkIf (cfg.llm.modelService.enable) {
        enable = true;
        listenAddress = cfg.llm.modelService.host;
        port = cfg.llm.modelService.port;
        openFirewall = cfg.llm.modelService.openFirewall;
        tls.enable = false;
        settings = {
          logLevel = "info";
          macros = {
            "models_dir" = cfg.llm.modelService.modelsDir;
            "default_ctx" = 16384;
            "threads" = 12;
            "ctx_checkpoints" = 32;
            "checkpoint_every_n_tokens" = 8192;
          };
          models = {
            "ggml-org--gpt-oss-20b" = {
              name = "ggml-org--gpt-oss-20b";
              description = "A thinking model from OpenAI";
              macros = {
                "model_file" = "ggml-org--gpt-oss-20b-mxfp4.gguf";
                "default_ctx" = 0;
                "temp" = 0.7;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --ubatch-size ''${ubatch_size} \
                --batch-size ''${batch_size} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --jinja
                '';
            };
            "unsloth--GLM-4.7-Flash-REAP-23B-A3B" = {
              name = "unsloth--GLM-4.7-Flash-REAP-23B-A3B";
              description = "unsloth quantization of GL-4.7-Flash, REAP'd";
              macros = {
                "model_file" = "unsloth--GLM-4.7-Flash-REAP-23B-A3B-UD-Q4_K_XL.gguf";
                "default_ctx" = 0;
                "temp" = 0.7;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "repetition_penalty" = 1.0;
                "top_p" = 1.0;
                "min_p" = 0.1;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --ubatch-size ''${ubatch_size} \
                --batch-size ''${batch_size} \
                --repeat-penalty ''${repetition_penalty} \
                --top-p ''${top_p} \
                --min-p ''${min_p} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --jinja
              '';
            };
            "unsloth--gemma-4-26B-A4B-it" = {
              name = "unsloth--gemma-4-26B-A4B-it";
              description = "unsloth quantization of gemma4";
              macros = {
                "model_file" = "unsloth--gemma-4-26B-A4B-it-MXFP4_MOE.gguf";
                "default_ctx" = 0;
                "temp" = 1.0;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 64;
                "ctx_checkpoints" = 4;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --ubatch-size ''${ubatch_size} \
                --batch-size ''${batch_size} \
                --top-p ''${top_p} \
                --top-k ''${top_k} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --no-mmap \
                --jinja
              '';
            };
            "unsloth--gemma-4-31B-it" = {
              name = "unsloth--gemma-4-31B-it";
              description = "unsloth quantization of gemma4";
              macros = {
                "model_file" = "unsloth--gemma-4-31B-it-UD-Q4_K_XL.gguf";
                "default_ctx" = 0;
                "temp" = 1.0;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 64;
                "ctx_checkpoints" = 4;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --ubatch-size ''${ubatch_size} \
                --batch-size ''${batch_size} \
                --top-p ''${top_p} \
                --top-k ''${top_k} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --no-mmap \
                --jinja
              '';
            };
            "unsloth--gemma-4-E4B-it" = {
              name = "unsloth--gemma-4-E4B-it";
              description = "unsloth quantization of gemma4";
              macros = {
                "model_file" = "unsloth--gemma-4-E4B-it-UD-Q4_K_XL.gguf";
                "default_ctx" = 0;
                "temp" = 1.0;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 64;
                "ctx_checkpoints" = 4;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --ubatch-size ''${ubatch_size} \
                --batch-size ''${batch_size} \
                --top-p ''${top_p} \
                --top-k ''${top_k} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --jinja
              '';
            };
            "unsloth--granite-4.0-h-micro" = {
              name = "unsloth--granite-4.0-h-micro";
              description = "unsloth quantization of granite 4.0 micro";
              macros = {
                "model_file" = "unsloth--granite-4.0-h-micro-UD-Q4_K_XL.gguf";
                "default_ctx" = 0;
                "temp" = 0.7;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --jinja
              '';
            };
            "unsloth--granite-4.0-h-small" = {
              name = "unsloth--granite-4.0-h-small";
              description = "unsloth quantization of granite 4.0 small";
              macros = {
                "model_file" = "unsloth--granite-4.0-h-small-UD-Q4_K_XL.gguf";
                "default_ctx" = 0;
                "temp" = 0.7;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --jinja
              '';
            };
            "unsloth--Qwen3.5-9B" = {
              name = "unsloth--Qwen3.5-9B";
              description = "unsloth quantization of qwen 3.5";
              macros = {
                "model_file" = "unsloth--Qwen3.5-9B-UD-Q4_K_XL.gguf";
                "default_ctx" = 0;
                "temp" = 0.6;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 20;
                "min_p" = 0.0;
                "presence_penalty" = 0.0;
                "repetition_penalty" = 1.0;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --ubatch-size ''${ubatch_size} \
                --batch-size ''${batch_size} \
                --top-p ''${top_p} \
                --top-k ''${top_k} \
                --min-p ''${min_p} \
                --repeat-penalty ''${repetition_penalty} \
                --presence-penalty ''${presence_penalty} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --jinja
              '';
            };
            "unsloth--Qwen3.5-27B" = {
              name = "unsloth--Qwen3.5-27B";
              description = "unsloth quantization of qwen 3.5";
              macros = {
                "model_file" = "unsloth--Qwen3.5-27B-UD-Q4_K_XL.gguf";
                "default_ctx" = 0;
                "temp" = 0.6;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 20;
                "min_p" = 0.0;
                "presence_penalty" = 0.0;
                "repetition_penalty" = 1.0;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --ubatch-size ''${ubatch_size} \
                --batch-size ''${batch_size} \
                --top-p ''${top_p} \
                --top-k ''${top_k} \
                --min-p ''${min_p} \
                --repeat-penalty ''${repetition_penalty} \
                --presence-penalty ''${presence_penalty} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --jinja
              '';
            };
            "unsloth--Qwen3.5-35B-A3B" = {
              name = "unsloth--Qwen3.5-35B-A3B";
              description = "unsloth quantization of qwen 3.5";
              macros = {
                "model_file" = "unsloth--Qwen3.5-35B-A3B-MXFP4_MOE.gguf";
                "default_ctx" = 0;
                "temp" = 0.6;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 20;
                "min_p" = 0.0;
                "presence_penalty" = 0.0;
                "repetition_penalty" = 1.0;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --ctx-size ''${default_ctx} \
                --temperature ''${temp} \
                --ubatch-size ''${ubatch_size} \
                --batch-size ''${batch_size} \
                --top-p ''${top_p} \
                --top-k ''${top_k} \
                --min-p ''${min_p} \
                --repeat-penalty ''${repetition_penalty} \
                --presence-penalty ''${presence_penalty} \
                --threads ''${threads} \
                --ctx-checkpoints ''${ctx_checkpoints} \
                --checkpoint-every-n-tokens ''${checkpoint_every_n_tokens} \
                --jinja
              '';
            };
          };
        };
      };

    # TODO: would apply to the local llm service, possibly comfy
    systemd.tmpfiles.rules = lib.mkIf (cfg.llm.modelService.enable) [
      "d ${cfg.llm.modelService.modelsDir} 0755 ${cfg.llm.modelService.modelsUser} ${toString cfg.llm.modelService.modelsGroup} -"
    ];

    # TODO: would apply to the local llm service, possibly comfy
    sys.software = with pkgs; lib.mkIf (cfg.llm.modelService.enable) [
      python3Packages.huggingface-hub
      llamaPkg # useful to run llama-server directly for debugging purposes
    ];

    services.open-webui = lib.mkIf (cfg.llm.web.enable) {
      enable = true;
      host = cfg.llm.web.host;
      port = cfg.llm.web.port;
      openFirewall = cfg.llm.web.openFirewall;
      stateDir = "/var/lib/open-webui";
      environmentFile = null;
      # https://docs.openwebui.com/getting-started/env-configuration
      environment = {
        # always favor settings from environment variables (when that variable
        # is a PersistentConfig variable);
        ENABLE_PERSISTENT_CONFIG = "False";
        #RESET_CONFIG_ON_START = "True";
        # ...
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        ENABLE_FORWARD_USER_INFO_HEADERS = "False";
        # ...
        WEBUI_AUTH = "True";
        ENABLE_SIGNUP = "False";
        ENABLE_SIGNUP_PASSWORD_CONFIRMATION = "True";
        WEBUI_SESSION_COOKIE_SAME_SITE = "strict";
        WEBUI_SESSION_COOKIE_SECURE = "True";
        WEBUI_AUTH_COOKIE_SAME_SITE = "strict";
        WEBUI_AUTH_COOKIE_SECURE = "True";
        #CORS_ALLOW_ORIGIN = "*";
        CORS_ALLOW_ORIGIN =
          let
            allowedOrigins = [
              "http://${cfg.llm.web.host}"
              "http://${cfg.llm.web.host}:${toString cfg.llm.web.port}"
              "http://localhost:${toString cfg.llm.web.port}"
              "http://127.0.0.1:${toString cfg.llm.web.port}"
              "https://${cfg.llm.web.host}"
              "https://${cfg.llm.web.host}:${toString cfg.llm.web.port}"
              "https://localhost:${toString cfg.llm.web.port}"
              "https://127.0.0.1:${toString cfg.llm.web.port}"
            ] ++ cfg.llm.extraAllowedOrigins;
            constructCorsString = origins: lib.concatStringsSep ";" origins;
            corsValue = constructCorsString allowedOrigins;
          in
          if cfg.llm.allowAllOrigins then "*" else corsValue;
        # ...
        GLOBAL_LOG_LEVEL = "DEBUG";
        # ...
        ENABLE_OLLAMA_API = "False";
        # ...
        DEFAULT_LOCALE = "en";
        DEFAULT_MODELS = "";
        DEFAULT_PINNED_MODELS = "";
        DEFAULT_USER_ROLE = "pending";
        # ...
        ENABLE_CHANNELS = "False";
        ENABLE_FOLDERS = "True";
        FOLDER_MAX_FILE_COUNT = "";
        ENABLE_NOTES = "True";
        ENABLE_MEMORIES = "True";
        ENV = "prod";
        ENABLE_REALTIME_CHAT_SAVE = "False";
        # ...
        ENABLE_OPENAI_API = "True";
        OPENAI_API_BASE_URL = "${cfg.llm.web.modelServiceUrl}/v1";
      } // (lib.optionalAttrs cfg.llm.searxng.enable {
        # ...
        ENABLE_WEB_SEARCH = "True";
        WEB_SEARCH_RESULT_COUNT = "5";
        WEB_SEARCH_CONCURRENT_REQUESTS = "10";
        WEB_LOADER_CONCURRENT_REQUESTS = "10";
        WEB_SEARCH_ENGINE = "searxng";
        SEARXNG_QUERY_URL = "http://${cfg.llm.searxng.host}:${toString cfg.llm.searxng.port}/search?q=<query>&format=json";
        SEARXNG_LANGUAGE = "all";
        WEB_LOADER_ENGINE = "safe_web";
        WEB_LOADER_TIMEOUT = "10.0"; # seconds; only applies to `safe_web`
      }) // (lib.optionalAttrs cfg.llm.comfy.enable {
        # ...
        ENABLE_IMAGE_GENERATION = "True";
        ENABLE_IMAGE_PROMPT_GENERATION = "True";
        IMAGE_GENERATION_ENGINE = "comfyui";
        COMFYUI_BASE_URL = "http://${cfg.llm.comfy.host}:${toString cfg.llm.comfy.port}";
        #COMFYUI_WORKFLOW = "<json string>";
        #COMFYUI_WORKFLOW_NODES = "[]"; # list[dict]
        # ...
        ENABLE_IMAGE_EDIT = "True";
        IMAGE_EDIT_ENGINE = "comfyui";
        IMAGES_EDIT_COMFYUI_BASE_URL = "http://${cfg.llm.comfy.host}:${toString cfg.llm.comfy.port}";
        #IMAGES_EDIT_COMFYUI_WORKFLOW = "<json string>";
        #IMAGES_EDIT_COMFYUI_WORKFLOW_NODES = "[]"; # list[dict]
      });
    };

    # from comfyui-nix flake
    services.comfyui = lib.mkIf (cfg.llm.comfy.enable) {
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
      trusted-substituters = [ ] ++ (if (cfg.llm.comfy.enable) then [
        # for comfyui-nix
        "https://comfyui.cachix.org"
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ] else [ ])
        ++ (if (cfg.llm.enable) then [
        # for llm-agents.nix
        "https://cache.numtide.com"
      ] else [ ]);
      trusted-public-keys = [ ] ++ (if (cfg.llm.comfy.enable) then [
        # for comfyui-nix
        "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ] else [ ])
        ++ (if (cfg.llm.enable) then [
        # for llm-agents.nix
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ] else [ ]);
    };

    services.searx = lib.mkIf (cfg.llm.searxng.enable) {
      enable = true;
      redisCreateLocally = true;
      package = pkgs.searxng;
      environmentFile = lib.mkIf (cfg.llm.searxng.environmentFile != null) cfg.llm.searxng.environmentFile;
      # (ref): https://docs.searxng.org/admin/searx.limiter.html
      limiterSettings = { };
      # (ref): https://github.com/open-webui/open-webui/discussions/9646#discussioncomment-12361163
      settings = {
        general = {
          debug = false;
          instance_name = "Local SearXNG Instnace";
          donation_url = false;
          conact_url = false;
          privacypolicy_url = false;
          enable_metrics = false;
        };
        server = {
          bind_address = cfg.llm.searxng.host;
          port = cfg.llm.searxng.port;
          limiter = false;
          public_instance = false;
          image_proxy = true;
          method = "GET";
        };
        ui = {
          static_use_hash = true;
          default_locale = "en";
          query_in_title = false;
          infinite_scroll = false;
          center_alignment = false;
          default_theme = "simple";
          theme_args.simple_style = "auto";
          search_on_category_select = false;
          hotkeys = "vim";
          url_formatting = "full";
        };
        search = {
          safe_search = 0;
          autocomplete = "duckduckgo";
          #autocomplete_min = 2;
          ban_time_on_fail = 5;
          max_ban_time_on_fail = 60;
          formats = [ "html" "json" "csv" "rss" ];
        };
        # (ref): https://docs.searxng.org/admin/settings/settings_engines.html
        # (ref): https://docs.searxng.org/dev/engines/index.html#engine-implementations
        engines = lib.mapAttrsToList (name: value: { inherit name; } // value) {
          # --- enabled ---
          "artic".disabled = false;
          "bing".disabled = false;
          "bing images".disabled = false;
          "bing videos".disabled = false;
          "crowdview" = {
            disabled = false;
            weight = 0.5;
          };
          "ddg definitions" = {
            disabled = false;
            weight = 2;
          };
          "deviantart".disabled = false;
          "duckduckgo".disabled = false;
          "duckduckgo images".disabled = false;
          "duckduckgo videos".disabled = false;
          "google".disabled = false;
          "google images".disabled = false;
          "google videos".disabled = false;
          "google news".disabled = false;
          "imgur".disabled = false;
          "library of congress".disabled = false;
          "mwmbl" = {
            disabled = false;
            weight = 0.4;
          };
          "openverse".disabled = false;
          "peertube".disabled = false;
          "qwant videos".disabled = false;
          "rumble".disabled = false;
          "sepiasearch".disabled = false;
          "svgrepo".disabled = false;
          "unsplash".disabled = false;
          "wallhaven".disabled = false;
          "wikibooks".disabled = false;
          "wikicommons.images".disabled = false;
          "wikidata" = {
            disabled = false;
            engine = "wikidata";
            shortcut = "wd";
            timeout = 3.0;
            weight = 2;
            display_type = ''["infobox"]'';
            tests = "*tests_infobox";
            catogories = "[general]";
          };
          "wikispecies" = {
            disabled = false;
            weight = 0.5;
          };
          "wikiversity" = {
            disabled = false;
            weight = 0.5;
          };
          "wikivoyage" = {
            disabled = false;
            weight = 0.5;
          };
          "youtube".disabled = false;
          # --- disabled ---
          "1x".disabled = true;
          "brave".disabled = true;
          "brave.images".disabled = true;
          "brave.news".disabled = true;
          "brave.videos".disabled = true;
          "curlie" = {
            engine = "xpath";
            shortcut = "cl";
            categories = "general";
            disabled = true;
            paging = true;
            lang_all = "";
            search_url = ''https://curlie.org/search?q={query}&lang = { lang }&start={pageno}&stime=92452189'';
            page_size = 20;
            results_xpath = ''//div [ @id = "site-list-content" ] /div [ @class="site-item" ]'';
            url_xpath = ''./div [ @class="title-and-desc" ]/a/@href'';
            title_xpath = ''./div[@class = "title-and-desc"]/a/div'';
            content_xpath = ''./div[@class="title-and-desc"]/div[@class="site-descr"]'';
            about = {
              website = "https://curlie.org/";
              wikidata_id = "Q60715723";
              use_official_api = false;
              require_api_key = false;
              results = "HTML";
            };
          };
          "currency".disabled = true;
          "dailymotion".disabled = true;
          "dictzone".disabled = true;
          "flickr".disabled = true;
          "google play movies".disabled = true;
          "invidious" = {
            engine = "invidious";
            disabled = true;
            base_url = [
              "https://inv.nadeko.net/"
              "https://yewtu.be/"
              "https://invidious.nerdvpn.de/"
            ];
            shortcut = "iv";
            timeout = 3.0;
          };
          "lingva".disabled = true;
          "material icons" = {
            disabled = true;
            weight = 0.2;
          };
          "mojeek".disabled = true;
          "odysee".disabled = true;
          "pinterest".disabled = true;
          "piped".disabled = true;
          "qwant".disabled = true;
          "qwant images".disabled = true;
          "vimeo".disabled = true;
          "wikiquote".disabled = true;
          "wikisource".disabled = true;
          "yacy images".disabled = true;
        };
        outgoing = {
          request_timeout = 5.0;
          max_request_timeout = 15.0;
          useragent_suffix = "";
          pool_connections = 100;
          pool_maxsize = 15;
          enable_http2 = true;
        };
        #plugins = [
        #  "Basic Calculator"
        #  "Hash plugin"
        #  #"Tor check plugin"
        #  "Open Access DOI rewrite"
        #  "Hostnames plugin"
        #  "Unit converter plugin"
        #  "Tracker URL remover"
        #];
      };
    };
  };
}

