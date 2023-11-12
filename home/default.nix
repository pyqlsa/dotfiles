{ config
, lib
, osConfig
, pkgs
, system
, inputs
, ...
}:
let
  python-with-packages = pkgs.python311.withPackages (ps:
    with ps; [
      pip
      setuptools
      virtualenv
    ]);
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

  home.packages = with pkgs;
    [
      # core
      curl
      fdupes
      file
      htop
      rsync
      wget
      zip
      unzip
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
      python-with-packages
      # - rust
      cargo
      rustc
      rustfmt
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
        my-nerdfonts
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
    platformTheme = "gtk";
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

  home.stateVersion = "22.05";
}
