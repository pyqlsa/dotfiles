{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.sys;
  # bash script to let dbus know about important env variables and
  # propagate them to relevent services run at the end of sway config
  # see
  # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # note: this is pretty much the same as  /etc/sway/config.d/nixos.conf but also restarts
  # some user services to make sure they have the correct environment variables
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  #configure-gtk = pkgs.writeTextFile {
  #  name = "configure-gtk";
  #  destination = "/bin/configure-gtk";
  #  executable = true;
  #  text =
  #    let
  #      schema = pkgs.gsettings-desktop-schemas;
  #      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
  #    in
  #    ''
  #      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
  #      gnome_schema=org.gnome.desktop.interface
  #      gsettings set $gnome_schema gtk-theme 'Dracula'
  #    '';
  #};

  makoConfig = ''
    sort=-time
    layer=overlay
    background-color=#262626
    width=200
    height=80
    border-size=2
    border-color=#173144
    border-radius=5
    icons=0
    max-icon-size=64
    default-timeout=5000
    ignore-timeout=1
    font=${cfg.desktop.tiling.font.notifications.name} ${toString cfg.desktop.tiling.font.notifications.size}

    [urgency=low]
    border-color=#cccccc

    [urgency=normal]
    border-color=#1b4b6e

    [urgency=high]
    border-color=#bf616a
    default-timeout=0

    [category=mpd]
    default-timeout=2000
    group-by=category
  '';

  fancy-sway-lock = pkgs.writeShellScriptBin "fancy-sway-lock" ''
    lockArgs=""

    for output in `swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.active == true) | .name'`
    do
      img="/tmp/''${output}-lock.png"
      ${pkgs.grim}/bin/grim -t png -o ''${output} ''${img}
      ${pkgs.imagemagick}/bin/convert ''${img} -scale 10% -scale 1000% ''${img}
      lockArgs="''${lockArgs} --image ''${output}:''${img}"
    done
    ${pkgs.swaylock}/bin/swaylock ''${lockArgs}
  '';

  processScreenshot = ''wl-copy -t image/png && notify-send "Screenshot copied to clipboard"'';

  sleepy-screens = ''
    swayidle timeout 2400 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"'
  '';

  # otherwise lauched qt apps don't pick up theme
  wofi-wrapped = pkgs.writeShellScriptBin "wofi-wrapped" ''
    export _JAVA_AWT_WM_NONREPARENTING=1
    export QT_QPA_PLATFORMTHEME=gtk2
    export QT_QPA_PLATFORM=wayland
    ${pkgs.wofi}/bin/wofi --show run --insensitive --height 200
  '';

  configFile = pkgs.writeText "sway.cfg" ''
    # --- Init ---
    # sway config file
    set $mod Mod1

    # set terminal
    set $term ${cfg.desktop.tiling.terminal}

    # application launcher
    set $menu ${wofi-wrapped}/bin/wofi-wrapped

    # display configuration
    output * background ${cfg.desktop.sway.background} fill
    ${optionalString (cfg.desktop.tiling.displayConfig != "") cfg.desktop.tiling.displayConfig}

    # auto lock the screen
    # need to solve media playing detection before continuing to use
    # todo...

    # --- Helpers ---
    exec dbus-sway-environment
    #exec_always configure-gtk

    # just sleep the screen
    exec ${sleepy-screens}

    # notifications
    exec ${pkgs.mako}/bin/mako --config ${pkgs.writeText "mako-config" makoConfig}

    ${optionalString config.hardware.bluetooth.enable ''
      # blueman applet
      exec ${pkgs.blueman}/bin/blueman-applet''}

    ${cfg.desktop.tiling.styleConfig}

    # --- Keymaps ---
    # Use Mouse+$mod to drag floating windows to their wanted position
    floating_modifier $mod

    # start a terminal
    bindsym $mod+Return exec $term

    # kill focused window
    bindsym $mod+Shift+q kill

    # launcher; should we add --no-startup-id ?
    bindsym $mod+d exec $menu

    # change focus
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # move focused window
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    # split in horizontal orientation
    bindsym $mod+h split h
    # split in vertical orientation
    bindsym $mod+v split v

    # enter fullscreen mode for the focused container
    bindsym $mod+f fullscreen toggle

    # change container layout (stacked, tabbed, toggle split)
    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    # toggle tiling / floating
    bindsym $mod+Shift+space floating toggle

    # change focus between tiling / floating windows
    bindsym $mod+space focus mode_toggle

    # focus the parent container
    bindsym $mod+a focus parent

    # focus the child container
    #bindsym $mod+d focus child

    # switch to workspace
    bindsym $mod+1 workspace 1
    bindsym $mod+2 workspace 2
    bindsym $mod+3 workspace 3
    bindsym $mod+4 workspace 4
    bindsym $mod+5 workspace 5
    bindsym $mod+6 workspace 6
    bindsym $mod+7 workspace 7
    bindsym $mod+8 workspace 8
    bindsym $mod+9 workspace 9
    bindsym $mod+0 workspace 10
    bindsym $mod+i workspace prev
    bindsym $mod+o workspace next

    # move focused container to workspace
    bindsym $mod+Shift+1 move container to workspace 1
    bindsym $mod+Shift+2 move container to workspace 2
    bindsym $mod+Shift+3 move container to workspace 3
    bindsym $mod+Shift+4 move container to workspace 4
    bindsym $mod+Shift+5 move container to workspace 5
    bindsym $mod+Shift+6 move container to workspace 6
    bindsym $mod+Shift+7 move container to workspace 7
    bindsym $mod+Shift+8 move container to workspace 8
    bindsym $mod+Shift+9 move container to workspace 9
    bindsym $mod+Shift+0 move container to workspace 10
    bindsym $mod+Shift+i move container to workspace prev
    bindsym $mod+Shift+o move container to workspace next

    # Input Devices
    ${optionalString (cfg.desktop.tiling.inputConfig != "") cfg.desktop.tiling.inputConfig}

    # Pulse Audio controls
    # run pactl list sinks
    bindsym XF86AudioRaiseVolume exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-volume 0 +5% #increase sound volume
    bindsym XF86AudioLowerVolume exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-volume 0 -5% #decrease sound volume
    bindsym XF86AudioMute exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-mute 0 toggle # mute sound

    # Sreen brightness controls
    bindsym --locked XF86MonBrightnessDown exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-
    bindsym --locked XF86MonBrightnessUp exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%+

    # keybinding to lock screen
    bindsym Control+$mod+l exec fancy-sway-lock

    # reload the configuration file
    bindsym $mod+Shift+c reload

    # exit sway (logs you out of your wayland session)
    bindsym $mod+Shift+e exec ${pkgs.sway}/bin/swaynag -t warning -m 'Do you really want to exit sway?' -B 'Yes, exit sway' 'swaymsg exit'

    # screenshots
    bindsym --release $mod+Print exec ${pkgs.grim}/bin/grim - | ${processScreenshot}
    bindsym --release $mod+Shift+Print exec ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d)" - | ${processScreenshot}

    #set $gnome-schema org.gnome.desktop.interface
    #exec_always {
    #  gsettings set $gnome-schema gtk-theme 'Breeze-Dark'
    #  gsettings set $gnome-schema icon-theme 'breeze-dark'
    #}

    ${cfg.desktop.tiling.resizeBlockConfig}

    ${cfg.desktop.tiling.barBlockConfig}
  '';
in
{
  options.sys.desktop.sway = {
    enable = mkEnableOption (lib.mdDoc "sway desktop");
    background = mkOption {
      type = types.package;
      description = "Background image to use";
      default = cfg.desktop.wallpaper;
    };
    terminal = mkOption {
      type = types.str;
      description = "Default terminal to run";
      default = "alacritty";
      example = "foot";
    };
  };

  config = mkIf (cfg.desktop.sway.enable) {
    # allow for running gnome things outside of gnome (like for using themes)
    programs.dconf.enable = true;
    environment.pathsToLink = [ "/libexec" ];
    services = {
      displayManager.defaultSession = "sway";
      xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
        };
        xkb.layout = "us";
      };
    };

    sys.software = with pkgs; [
      sway
      dbus-sway-environment
      fancy-sway-lock
      wayland
      xdg-utils # for opening default programs when clicking links
      glib # gsettings
      swaylock
      swayidle
      grim # screenshot functionality
      slurp # screenshot functionality
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      wofi
      wofi-wrapped
      libsForQt5.qt5.qtwayland # unsure if explicitly necessary
      mako # notification system developed by swaywm maintainer
      libnotify
      i3status-rust
      foot # another terminal emulator
      networkmanagerapplet # to get nm-connection-editor
      # gtk appears to not be an issue when configuring through home-manager
      #configure-gtk
      #dracula-theme # gtk theme
      #gnome3.adwaita-icon-theme # default gnome cursors
    ];

    # xdg-desktop-portal works by exposing a series of D-Bus interfaces
    # known as portals under a well-known name
    # (org.freedesktop.portal.Desktop) and object path
    # (/org/freedesktop/portal/desktop).
    # The portal interfaces include APIs for file access, opening URIs,
    # printing and others.
    # is this causing an issue w/ firefox launching slowly?
    # https://bbs.archlinux.org/viewtopic.php?id=275618
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      # gtk portal needed to make gtk apps happy
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # enable sway window manager
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    # set config system-wide rather than per user
    environment.etc."sway/config" = {
      source = configFile;
    };

    # probably need to find a better way of setting these
    environment.sessionVariables = {
      "_JAVA_AWT_WM_NONREPARENTING" = "1";
      "QT_QPA_PLATFORMTHEME" = "gtk2";
      "QT_QPA_PLATFORM" = "wayland";
    };
  };
}
