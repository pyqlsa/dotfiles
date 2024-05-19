{ config
, lib
, osConfig
, pkgs
, system
, inputs
, ...
}:
let
  select-nerdfonts = pkgs.nerdfonts.override { fonts = [ "FiraCode" "FiraMono" ]; };
  font-name = "FiraMono Nerd Font Mono";

  uiTheme = with pkgs; {
    dark = true;
    icons = {
      package = breeze-icons;
      name = "breeze-dark";
    };
    gtk = {
      package = breeze-gtk;
      name = "Breeze-Dark";
    };
    qt = {
      package = libsForQt5.breeze-qt5;
      name = "breeze-dark";
    };
    fonts = {
      default = {
        package = select-nerdfonts;
        name = font-name;
      };
      monospace = {
        package = select-nerdfonts;
        name = font-name;
      };
    };
  };
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = osConfig.sys.user.name;
  home.homeDirectory = "/home/${osConfig.sys.user.name}";

  home.packages = with pkgs;
    [
      # core
      curl
      fdupes
      file
      htop
      nmap
      p7zip
      ripgrep
      rsync
      s-tui
      stress
      wget
      zip
      unzip
      xxd
      # vpn
      protonvpn-cli
      # dev
      git
      gnumake
      jq
      neovimPQ
      shellcheck
      # - go
      go
      gcc
      # - python
      python-basic
      # - rust
      cargo
      rustc
      rustfmt
      # - media
      exiftool
      ffmpeg
      imagemagick
      yt-dlp
    ]
    ++ (
      if osConfig.sys.desktop.enable
      then [
        # core
        keychain
        # vpn
        protonvpn-gui
        # graphical
        firefox
        chromium
        # productivity
        libreoffice-qt
        hunspell
        hunspellDicts.en_US-large
        # media
        geeqie
        gimp
        gpodder
        inkscape
        vlc
        # fonts and themes
        select-nerdfonts
        libsForQt5.qt5ct
        libsForQt5.qtstyleplugins
        uiTheme.fonts.monospace.package
      ]
      else [ ]
    );

  # --- end when desktop/graphical
  fonts.fontconfig.enable = osConfig.sys.desktop.enable;

  gtk = lib.mkIf (osConfig.sys.desktop.enable) {
    enable = true;

    iconTheme.package = uiTheme.icons.package;
    iconTheme.name = uiTheme.icons.name;

    theme.package = uiTheme.gtk.package;
    theme.name = uiTheme.gtk.name;

    font.package = uiTheme.fonts.default.package;
    font.name = uiTheme.fonts.default.name;
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = uiTheme.dark;
    };
  };

  # see sessionvarabiles comment below...
  qt = lib.mkIf (osConfig.sys.desktop.enable) {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = uiTheme.qt.name;
      package = uiTheme.qt.package;
    };
  };

  # only gets sourced when home manager is managing the shell;
  # this concept is important not only for this snippet, but also for other
  # theme-related variables
  home.sessionVariables = lib.mkIf (osConfig.sys.desktop.enable) {
    GTK_USE_PORTAL = 1;
    EDITOR = "vim";
  };

  # libadwaita doesn't respect any precedent
  dconf.settings."org/gnome/desktop/interface" = lib.mkIf (osConfig.sys.desktop.enable) {
    monospace-font-name = uiTheme.fonts.monospace.name;
    color-scheme =
      if uiTheme.dark
      then "prefer-dark"
      else "prefer-light";
    cursor-size = 24;
  };

  programs.alacritty = lib.mkIf (osConfig.sys.desktop.enable) {
    enable = true;
    settings = import ./alacritty-settings.nix { inherit font-name; };
  };
  # --- end when desktop/graphical

  # --- when virt-manager enabled
  dconf.settings."org/virt-manager/virt-manager/connections" = lib.mkIf (osConfig.sys.virtualisation.virt-manager.enable) {
    autoconnect = [ "qemu:///system" ];
    uris = [ "qemu:///system" ];
  };
  # --- end virt-manager

  programs.git = {
    enable = true;
    userName = osConfig.sys.user.gitUsername;
    userEmail = osConfig.sys.user.gitEmail;
    extraConfig = {
      url = {
        "ssh://git@github.com" = {
          insteadOf = "https://github.com";
        };
      };
    };
  };

  programs.zsh = lib.mkIf (osConfig.sys.user.zshDefault) {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
    };
    dotDir = ".config/zsh";
    shellAliases = {
      l = "ls -alh";
      la = "ls -a";
      ll = "ls -l";
      ls = "ls --color=tty";
      history = "history 1";
    };
    # --- in order
    # if it is needed by a command run non-interactively: .zshenv
    # if it should be updated on each new shell: .zshenv
    envExtra = '''';
    # if it runs a command which may take some time to complete: .zprofile
    profileExtra = '''';
    # if it is related to interactive usage: .zshrc
    initExtra = ''
      # --- prompt ---
      # https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
      # adapted from: https://gist.github.com/romkatv/2a107ef9314f0d5f76563725b42f7cab

      # Usage: prompt-length TEXT [COLUMNS]
      function prompt-length() {
        emulate -L zsh
        local -i COLUMNS=''${2:-COLUMNS}
        local -i x y=''${#1} m
        if (( y )); then
          while (( ''${''${(%):-$1%$y(l.1.0)}[-1]} )); do
            x=y
            (( y *= 2 ))
          done
          while (( y > x + 1 )); do
            (( m = x + (y - x) / 2 ))
            (( ''${''${(%):-$1%$m(l.x.y)}[-1]} = m ))
          done
        fi
        typeset -g REPLY=$x
      }

      # Usage: fill-line LEFT RIGHT
      #
      # Sets REPLY to LEFT<spaces>RIGHT with enough spaces in
      # the middle to fill a terminal line.
      function fill-line() {
        emulate -L zsh
        prompt-length $1
        local -i left_len=REPLY
        prompt-length $2 9999
        local -i right_len=REPLY
        local -i pad_len=$((COLUMNS - left_len - right_len - ''${ZLE_RPROMPT_INDENT:-1}))
        if (( pad_len < 1 )); then
          # Not enough space for the right part. Drop it.
          typeset -g REPLY=$1
        else
          local pad=''${(pl.$pad_len.. .)}  # pad_len spaces
          typeset -g REPLY=''${1}''${pad}''${2}
        fi
      }

      # Sets PROMPT and RPROMPT.
      #
      # Requires: prompt_percent and no_prompt_subst.
      function set-prompt() {
        emulate -L zsh
        local git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
        git_branch="''${git_branch//\%/%%}"  # escape '%'
        git_branch=$([ ! -z $git_branch ] && echo " [''${git_branch}]")

        local venv_info=$([ $VIRTUAL_ENV ] && echo "("$(basename "$VIRTUAL_ENV")") ")
        local nix_shell=$([ ! -z $IN_NIX_SHELL ] && echo '(nix-shell) ')

        # foo                              bar
        # > _                              baz
        #

        #PS1=$'%B%(?..[%?] )%b%n@%U%m%u> '
        #RPS1='%F{green}%~%f'

        local top_left="''${venv_info}%F{magenta}''${nix_shell}%f%F{cyan}%n%f@%U%F{blue}%m%f%u"
        local top_right="%F{green}%~%f%F{blue}''${git_branch}%f"
        local bottom_left='%B%(?..[%?] )%b%(!.#.>)%f '
        local bottom_right=""

        local REPLY
        fill-line "$top_left" "$top_right"
        PROMPT=$REPLY$'\n'$bottom_left
        RPROMPT=$bottom_right
      }

      setopt no_prompt_{bang,subst} prompt_{cr,percent,sp}
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd set-prompt
      # --- end prompt ---


      # Home and End Key Bindings
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      bindkey '^[[3~' delete-char

      # Extras not to be controlled in git
      if [ -f ~/.zsh_extras ]; then
          . ~/.zsh_extras
      fi

      # Depending on shell and system, either HOST or HOSTNAME is set
      [[ -z "''${HOSTNAME}" ]] && HOSTNAME=''${HOST}

      # Keychain
      [[ -x $(which keychain) ]] && \
        $(which keychain) --nogui ''${HOME}/.ssh/id_ed25519 && \
        source ''${HOME}/.keychain/''${HOSTNAME}-sh

      # Terraform completions
      #[[ -x $(which terraform) ]] && \
      #  complete -C $(which terraform) terraform
    '';
    # if it is a command to be run when the shell is fully setup: .zlogin
    loginExtra = ''
      #export PATH="$PATH:$HOME/go/bin"
    '';
    # if it releases a resource acquired at login: .zlogout
    logoutExtra = '''';
  };

  home.stateVersion = "24.05";
}
