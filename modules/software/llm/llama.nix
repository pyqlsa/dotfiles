{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys;

  llamaPkg =
    if cfg.llm.shared.gpu-type == "auto" then
      if cfg.hardware.amd.enable then
        pkgs.llama-cpp.override { rocmSupport = true; }
      else
        if cfg.hardware.nvidia.enable then
          pkgs.llama-cpp.override { cudaSupport = true; }
        else
          pkgs.llama-cpp
    else
      if cfg.llm.shared.gpu-type == "amd" then
        pkgs.llama-cpp.override { rocmSupport = true; }
      else
        if cfg.llm.shared.gpu-type == "nvidia" then
          pkgs.llama-cpp.override { cudaSupport = true; }
        else
          if cfg.llm.shared.gpu-type == "vulkan" then
            pkgs.llama-cpp.override { vulkanSupport = true; }
          else
            if cfg.llm.shared.gpu-type == "none" then
              pkgs.llama-cpp
            else
              pkgs.llama-cpp
  ;
in
{
  options.sys.llm.llama = {
    enable = mkEnableOption (lib.mdDoc "enable the llama");
    host = mkOption {
      type = with types; str;
      description = "host for the llama";
      default = "127.0.0.1";
      example = "0.0.0.0";
    };
    port = mkOption {
      type = with types; port;
      description = "port number for the llama";
      default = 8080;
      example = 11343;
    };
    openFirewall = mkEnableOption (lib.mdDoc "open the firewall for the llama");
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

  config = lib.mkIf (cfg.llm.llama.enable) {
    sys.llm.llama.modelsUser = lib.mkDefault "${config.sys.user.name}";

    services.llama-swap =
      let
        llama-server = "${llamaPkg}/bin/llama-server";
      in
      {
        enable = true;
        listenAddress = cfg.llm.llama.host;
        port = cfg.llm.llama.port;
        openFirewall = cfg.llm.llama.openFirewall;
        tls.enable = false;
        settings = {
          logLevel = "info";
          macros = {
            "models_dir" = cfg.llm.llama.modelsDir;
            "default_ctx" = 16384;
            "threads" = 12;
            "ctx_checkpoints" = 32;
          };
          models = {
            "unsloth--GLM-4.7-Flash-REAP-23B-A3B" = {
              name = "unsloth--GLM-4.7-Flash-REAP-23B-A3B";
              description = "unsloth quantization of GL-4.7-Flash, REAP'd";
              macros = {
                "model_file" = "unsloth--GLM-4.7-Flash-REAP-23B-A3B-UD-Q4_K_XL.gguf";
                "default_ctx" = 202752;
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
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
            "unsloth--gemma-4-26B-A4B-it" = {
              name = "unsloth--gemma-4-26B-A4B-it";
              description = "unsloth quantization of gemma4";
              macros = {
                "model_file" = "unsloth--gemma-4-26B-A4B-it-MXFP4_MOE.gguf";
                "default_ctx" = 262144;
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
                --no-mmap \
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
            "unsloth--gemma-4-31B-it" = {
              name = "unsloth--gemma-4-31B-it";
              description = "unsloth quantization of gemma4";
              macros = {
                "model_file" = "unsloth--gemma-4-31B-it-UD-Q4_K_XL.gguf";
                "default_ctx" = 262144;
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
                --no-mmap \
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
            "unsloth--gemma-4-E4B-it" = {
              name = "unsloth--gemma-4-E4B-it";
              description = "unsloth quantization of gemma4";
              macros = {
                "model_file" = "unsloth--gemma-4-E4B-it-UD-Q4_K_XL.gguf";
                "default_ctx" = 131072;
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
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
            "unsloth--Qwen3.5-9B" = {
              name = "unsloth--Qwen3.5-9B";
              description = "unsloth quantization of qwen 3.5";
              macros = {
                "model_file" = "unsloth--Qwen3.5-9B-UD-Q4_K_XL.gguf";
                "default_ctx" = 262144;
                "temp" = 0.6;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 20;
                "min_p" = 0.0;
                "presence_penalty" = 0.0;
                "repetition_penalty" = 1.1;
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
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
            "unsloth--Qwen3.6-27B" = {
              name = "unsloth--Qwen3.6-27B";
              description = "unsloth quantization of qwen 3.6";
              macros = {
                "model_file" = "unsloth--Qwen3.6-27B-UD-Q4_K_XL.gguf";
                "default_ctx" = 262144;
                "temp" = 0.6;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 20;
                "min_p" = 0.0;
                "presence_penalty" = 0.0;
                "repetition_penalty" = 1.1;
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
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
            "unsloth--Qwen3.6-35B-A3B" = {
              name = "unsloth--Qwen3.6-35B-A3B";
              description = "unsloth quantization of qwen 3.6";
              macros = {
                "model_file" = "unsloth--Qwen3.6-35B-A3B-MXFP4_MOE.gguf";
                "default_ctx" = 262144;
                "temp" = 0.6;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 20;
                "min_p" = 0.0;
                "presence_penalty" = 0.0;
                "repetition_penalty" = 1.1;
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
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
            "unsloth--Qwen3.6-35B-A3B-MTP" = {
              name = "unsloth--Qwen3.6-35B-A3B-MTP";
              description = "unsloth quantization of qwen 3.6";
              macros = {
                "model_file" = "unsloth--Qwen3.6-35B-A3B-MTP-MXFP4_MOE.gguf";
                "default_ctx" = 262144;
                "temp" = 0.6;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 20;
                "min_p" = 0.0;
                "presence_penalty" = 0.0;
                "repetition_penalty" = 1.1;
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
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
            "unsloth--Qwen3.8-27B" = {
              name = "unsloth--Qwen3.8-27B";
              description = "unsloth quantization of qwen 3.8";
              macros = {
                #"model_file" = "unsloth/Qwen3.8-27B-GGUF/Qwen3.8-27B-UD-Q4_K_XL.gguf";
                "model_file" = "unsloth/Qwen3.8-27B-GGUF/Qwen3.8-27B-UD-Q5_K_M.gguf";
                "mmproj_file" = "unsloth/Qwen3.8-27B-GGUF/mmproj-F16.gguf";
                "default_ctx" = 262144;
                "temp" = 1.0;
                "ubatch_size" = 2048;
                "batch_size" = 2048;
                "top_p" = 0.95;
                "top_k" = 20;
                "min_p" = 0.0;
                "presence_penalty" = 0.0;
                "repetition_penalty" = 1.1;
              };
              env = [
                "CUDA_VISIBLE_DEVICES=0,1" # use discrete gpus, skip integrated gpu; core dumps when running on integrated gpu likely due to mxfp4 quant
              ];
              #  --spec-type draft-mtp \
              #  --spec-draft-n-max 3 \
              #  --spec-draft-p-min 0.70 \
              #  --spec-draft-ngl all \
              #  --spec-draft-type-k q8_0 \
              #  --spec-draft-type-v q8_0 \
              cmd = ''${llama-server} --port ''${PORT} --no-webui \
                --model ''${models_dir}/''${model_file} \
                --mmproj ''${models_dir}/''${mmproj_file} \
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
                --n-gpu-layers 999 \
                --split-mode layer \
                --cache-type-k q8_0 \
                --cache-type-v q8_0 \
                --jinja
              '';
            };
          };
        };
      };

    # TODO: would apply to the local llama service, possibly comfy
    systemd.tmpfiles.rules = [
      "d ${cfg.llm.llama.modelsDir} 0755 ${cfg.llm.llama.modelsUser} ${toString cfg.llm.llama.modelsGroup} -"
    ];

    # TODO: would apply to the local llama service, possibly comfy
    sys.software = with pkgs; [
      python3Packages.huggingface-hub
      llamaPkg # useful to run llama-server directly for debugging purposes
    ];
  };
}

