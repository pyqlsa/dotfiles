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
  options.sys.searxng = {
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

  config = lib.mkIf (cfg.searxng.enable) {
    services.searx = {
      enable = true;
      redisCreateLocally = true;
      package = pkgs.searxng;
      environmentFile = lib.mkIf (cfg.searxng.environmentFile != null) cfg.searxng.environmentFile;
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
          bind_address = cfg.searxng.host;
          port = cfg.searxng.port;
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
          default_lang = "en";
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

