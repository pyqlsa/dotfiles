{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.sys;
  vim-mini = (pkgs.neovim.override {
    vimAlias = true;
    viAlias = true;
    configure = {
      packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-nix vim-lastplace ];
        opt = [ ];
      };
      customRC = ''
        set termguicolors
        syntax enable
        set nocompatible
        set backspace=indent,eol,start
        set background=dark
        set tabstop=2
        set shiftwidth=2
        set softtabstop=2
        set expandtab
        set number
        colorscheme lunaperche
      '';
    };
  });
in
{
  options.sys.vim = {
    enable = mkOption {
      type = types.bool;
      description = "minimal opinionated (neo)vim configurations";
      default = true;
    };
  };

  config = mkIf (cfg.vim.enable) {
    environment.variables = {
      EDITOR = "vim";
    };

    sys.software = with pkgs; [
      vim-mini
    ];
  };
}
