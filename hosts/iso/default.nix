{ inputs
, overlays
, system
, ...
}:
with inputs;
let
  pkgs = import nixpkgs {
    inherit system overlays;
    config = { allowUnfree = true; };
  };
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
nixpkgs.lib.nixosSystem {
  inherit system pkgs;
  modules = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ({ pkgs, config, ... }: {
      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
      };

      boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
      #boot.kernelPackages = pkgs.linuxPackages_latest;
      #boot.supportedFilesystems = lib.mkForce [
      #  "btrfs"
      #  "cifs"
      #  "f2fs"
      #  "jfs"
      #  "ntfs"
      #  "reiserfs"
      #  "vfat"
      #  "xfs"
      #];

      environment.systemPackages = with pkgs; [
        acpi
        btrfs-progs
        cryptsetup
        dmidecode
        exfat
        hwdata
        iotop
        lm_sensors
        #ntfsprogs
        nvme-cli
        pciutils
        smartmontools
        usbutils
        bind
        file
        lshw
        openssl
        htop
        screen
        tmux
        coreutils-full
        squashfsTools
        git
        gh
        vim-mini
        neovimPQ
      ];
    })
  ];
}
