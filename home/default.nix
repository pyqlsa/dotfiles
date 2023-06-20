{ config
, lib
, pkgs
, system
, inputs
, ...
}:
let
  my-python-packages = python-packages:
    with python-packages; [
      pip
    ];
  python-with-my-packages = pkgs.python310.withPackages my-python-packages;
  my-nerdfonts = pkgs.nerdfonts.override { fonts = [ "FiraCode" "FiraMono" ]; };
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
        package = my-nerdfonts;
        name = font-name;
      };
      monospace = {
        package = my-nerdfonts;
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
  home.username = "pyqlsa";
  home.homeDirectory = "/home/pyqlsa";

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # core
    curl
    fdupes
    file
    htop
    keychain
    rsync
    wget
    zip
    unzip
    # graphical
    firefox
    # productivity
    libreoffice-qt
    hunspell
    hunspellDicts.en_US-large
    # dev
    git
    gnumake
    jq
    neovimPQ
    shellcheck
    # - go
    go_1_19
    gcc
    # - python
    python-with-my-packages
    # - rust
    cargo
    rustc
    rustfmt
    # media
    geeqie
    gimp
    gpodder
    inkscape
    vlc
    # fonts and themes
    my-nerdfonts
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugins
    uiTheme.fonts.monospace.package
  ];

  gtk = {
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
  qt = {
    enable = true;
    platformTheme = "gtk";
    style = {
      name = uiTheme.qt.name;
      package = uiTheme.qt.package;
    };
  };

  # only gets sourced when home manager is managing the shell;
  # this concept is important not only for this snippet, but also for other
  # theme-related variables
  home.sessionVariables = {
    GTK_USE_PORTAL = 1;
    EDITOR = "vim";
  };

  # libadwaita doesn't respect any precedent
  dconf.settings."org/gnome/desktop/interface" = {
    monospace-font-name = uiTheme.fonts.monospace.name;
    color-scheme =
      if uiTheme.dark
      then "prefer-dark"
      else "prefer-light";
    cursor-size = 24;
  };

  programs.git = {
    enable = true;
    userName = "pyqlsa";
    userEmail = "26353308+pyqlsa@users.noreply.github.com";
    extraConfig = {
      url = {
        "ssh://git@github.com" = {
          insteadOf = "https://github.com";
        };
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;
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
      # Prompts
      export PROMPT='%B%(?..[%?] )%b%n@%U%m%u> '
      export RPS1='%F{green}%~%f'

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

  programs.alacritty = {
    enable = true;
    settings = import ./alacritty-settings.nix { inherit font-name; };
  };

  home.stateVersion = "22.05";
}
