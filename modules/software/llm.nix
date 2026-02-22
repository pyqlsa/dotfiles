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

  comfyCfg = { config, options, ... }: {
    options = {
      enable = mkEnableOption (lib.mdDoc "enable comfy-ui");
      host = mkOption {
        type = types.str;
        description = "host for the comfy-ui service";
        default = "127.0.0.1";
        example = "0.0.0.0";
      };
      port = mkOption {
        type = types.number;
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
        type = types.str;
        description = "host for the searxng service";
        default = "127.0.0.1";
        example = "0.0.0.0";
      };
      port = mkOption {
        type = types.number;
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
          if cfg.llm.gpu-type == "vulkan" then
            pkgs.ollama-vulkan
          else
            if cfg.llm.gpu-type == "none" then
              pkgs.ollama-cpu
            else
              pkgs.ollama
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
      example = { enable = true; host = "127.0.0.1"; port = 8080; openFirewall = false; };
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
      openFirewall = cfg.llm.openFirewall;
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
        CORS_ALLOW_ORIGIN =
          let
            allowedOrigins = [
              "http://${cfg.llm.web.host}:${toString cfg.llm.web.port}"
              "http://localhost:${toString cfg.llm.web.port}"
              "http://127.0.0.1:${toString cfg.llm.web.port}"
              "https://${cfg.llm.web.host}:${toString cfg.llm.web.port}"
              "https://localhost:${toString cfg.llm.web.port}"
              "https://127.0.0.1:${toString cfg.llm.web.port}"
            ];
            constructCorsString = origins: lib.concatStringsSep ";" origins;
            corsValue = constructCorsString allowedOrigins;
          in
          corsValue;
        # ...
        GLOBAL_LOG_LEVEL = "INFO";
        # ...
        OLLAMA_BASE_URL = "http://${cfg.llm.host}:${toString cfg.llm.port}";
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
        ENABLE_OPENAI_API = "False";
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
      gpuSupport = if cfg.llm.comfy.gpuSupport == null then comfyGpu else cfg.llmconfy.forceGpuSupport;
      enableManager = false;
      listenAddress = cfg.llm.comfy.host;
      port = cfg.llm.comfy.port;
      openFirewall = cfg.llm.comfy.openFirewall;
      extraArgs = cfg.llm.comfy.extraArgs;
      environment = cfg.llm.comfy.environment;
    };

    # because we're using the comfyui-nix flake
    nix.settings = lib.mkIf (cfg.llm.comfy.enable) {
      trusted-substituters = [
        #"https://cache.nixos.org"
        "https://comfyui.cachix.org"
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-public-keys = [
        #"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
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
          # enabled
          "duckduckgo".disabled = false;
          "bing".disabled = false;
          "mwmbl".disabled = false;
          "mwmbl".weight = 0.4;
          "crowdview".disabled = false;
          "crowdview".weight = 0.5;
          "ddg definitions".disabled = false;
          "ddg definitions".weight = 2;
          "wikibooks".disabled = false;
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
          "wikispecies".disabled = false;
          "wikispecies".weight = 0.5;
          "wikiversity".disabled = false;
          "wikiversity".weight = 0.5;
          "wikivoyage".disabled = false;
          "wikivoyage".weight = 0.5;
          "bing images".disabled = false;
          "google images".disabled = false;
          "artic".disabled = false;
          "deviantart".disabled = false;
          "imgur".disabled = false;
          "library of congress".disabled = false;
          "openverse".disabled = false;
          "svgrepo".disabled = false;
          "unsplash".disabled = false;
          "wallhaven".disabled = false;
          "wikicommons.images".disabled = false;
          "bing videos".disabled = false;
          "google videos".disabled = false;
          "qwant videos".disabled = false;
          "peertube".disabled = false;
          "rumble".disabled = false;
          "sepiasearch".disabled = false;
          "youtube".disabled = false;
          # disabled
          "brave".disabled = true;
          "mojeek".disabled = true;
          "qwant".disabled = true;
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
          "wikiquote".disabled = true;
          "wikisource".disabled = true;
          "currency".disabled = true;
          "dictzone".disabled = true;
          "lingva".disabled = true;
          "brave.images".disabled = true;
          "duckduckgo images".disabled = true;
          "qwant images".disabled = true;
          "1x".disabled = true;
          "flickr".disabled = true;
          "material icons".disabled = true;
          "material icons".weight = 0.2;
          "pinterest".disabled = true;
          "yacy images".disabled = true;
          "brave.videos".disabled = true;
          "duckduckgo videos".disabled = true;
          "dailymotion".disabled = true;
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
          "odysee".disabled = true;
          "piped".disabled = true;
          "vimeo".disabled = true;
          "brave.news".disabled = true;
          "google news".disabled = true;
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

