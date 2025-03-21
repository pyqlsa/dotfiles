{ inputs
, overlays
, system
, install-base
, extra-modules ? [ ]
, ...
}:
with inputs;
let
  lib = nixpkgs.lib;
  pkgs = import nixpkgs {
    inherit system overlays;
    config = { allowUnfree = true; };
  };
  vim-mini = (pkgs.neovim.override {
    vimAlias = false;
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
  modules = extra-modules ++ [
    install-base
    ({ pkgs, config, ... }: {
      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
      };

      #boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
      #boot.kernelPackages = pkgs.linuxPackages_latest;
      #boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
      #boot.supportedFilesystems = lib.mkForce [ "btrfs" "cifs" "f2fs" "jfs" "ntfs" "reiserfs" "vfat" "xfs" ];

      users.users.root = {
        initialHashedPassword = lib.mkForce "!";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGrK3R3Yo3uBAORs2QFfERsvQh/D6n3f5Em3cvrnr/N pyqlsa"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJtSB0+FKOQneFprWC/uXbnw2zMAxMrpQ6SsX4w1A7/ pyqlsa"
        ];
      };

      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PermitRootLogin = "yes";
          PasswordAuthentication = false;
        };
        banner = ''
                    /\
                   /**\
                  /****\   /\
                 /      \ /**\
                /  /\    /    \        /\    /\  /\      /\            /\/\/\  /\
               /  /  \  /      \      /  \/\/  \/  \  /\/  \/\  /\  /\/ / /  \/  \
              /  /    \/ /\     \    /    \ \  /    \/ /   /  \/  \/  \  /    \   \
             /  /      \/  \/\   \  /      \    /   /    \
          __/__/_______/___/__\___\__________________________________________________
        '';
      };
      networking.firewall.allowedTCPPorts = [ 22 ];
      networking.firewall.allowPing = true;

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
        tmux
        coreutils-full
        squashfsTools
        git
        gh
        vim-mini
        neovimPQ
        parted
      ];
    })
  ];
}
