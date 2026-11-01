{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys;
in
{
  options.sys.llm.web = {
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
    llamaUrl = mkOption {
      type = with types; str;
      description = "url for the language model service to use";
      default = "http://${cfg.llm.llama.host}:${toString cfg.llm.llama.host}";
      example = "https://example.com";
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
  };

  config = lib.mkIf (cfg.llm.web.enable) {
    services.open-webui = {
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
        OPENAI_API_BASE_URL = "${cfg.llm.web.llamaUrl}/v1";
      } // (lib.optionalAttrs cfg.searxng.enable {
        # ...
        ENABLE_WEB_SEARCH = "True";
        WEB_SEARCH_RESULT_COUNT = "5";
        WEB_SEARCH_CONCURRENT_REQUESTS = "10";
        WEB_LOADER_CONCURRENT_REQUESTS = "10";
        WEB_SEARCH_ENGINE = "searxng";
        SEARXNG_QUERY_URL = "http://${cfg.searxng.host}:${toString cfg.searxng.port}/search?q=<query>&format=json";
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
  };
}

