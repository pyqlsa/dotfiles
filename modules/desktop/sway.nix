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
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
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

  statusBarConfig = ''
    [[block]]
    block = "disk_space"
    path = "/"
    alias = "/"
    info_type = "used"
    format = "{used} / {total}"
    unit = "GB"
    interval = 20
    warning = 80.0
    alert = 90.0

    [[block]]
    block = "memory"
    format_mem = "{mem_used}"
    interval = 5
    warning_mem = 70
    critical_mem = 90

    [[block]]
    block = "cpu"
    interval = 1
    format = "{utilization}"

    #[[block]]
    #block = "temperature"
    #collapsed = false
    #scale = "celsius"
    #interval = 10
    #format = "$average"
    #chip = "k10temp*"
    #inputs = ["Tctl"]

    [[block]]
    block = "sound"
    format = "{output_description} {volume}"

    [[block]]
    block = "time"
    interval = 5
    format = "%a %b %d %H:%M %Z %Y"
  '';

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
    font=${cfg.desktop.sway.font.notifications.name} ${toString cfg.desktop.sway.font.notifications.size}

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
    set $term ${cfg.desktop.sway.terminal}

    # application launcher
    set $menu ${wofi-wrapped}/bin/wofi-wrapped

    # display configuration
    output * background ${cfg.desktop.sway.background} fill

    # auto lock the screen
    # need to solve media playing detection before continuing to use
    # todo...

    # just sleep the screen
    exec ${sleepy-screens}

    # notifications
    exec ${pkgs.mako}/bin/mako --config ${pkgs.writeText "mako-config" makoConfig}

    ${optionalString config.networking.networkmanager.enable ''
      # network manager applet
      exec ${pkgs.networkmanagerapplet}/bin/nm-applet''}
    ${optionalString config.hardware.bluetooth.enable ''
      # blueman applet
      exec ${pkgs.blueman}/bin/blueman-applet''}

    # --- Helpers ---
    exec_always dbus-sway-environment
    #exec_always configure-gtk

    # --- Style ---
    # Font for window titles. Will also be used by the bar unless a different font
    # is used in the bar {} block below.
    font ${cfg.desktop.sway.font.title.name} ${toString cfg.desktop.sway.font.title.size}
    default_border normal

    # Colors!
    # class                 border  bground text    indicator child_border
    client.focused          #444444 #333333 #DBDBDB #285577   #393939
    client.focused_inactive #333333 #222222 #888888 #484E50   #292929
    client.unfocused        #333333 #222222 #888888 #484E50   #292929
    client.urgent           #2F343A #661A1A #DBDBDB #661A1A   #661A1A
    client.placeholder      #000000 #0C0C0C #DBDBDB #000000   #0C0C0C
    client.background       #262626

    # Gaps!
    gaps inner 5px

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

    # Pulse Audio controls
    # run pactl list sinks
    bindsym XF86AudioRaiseVolume exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-volume 0 +5% #increase sound volume
    bindsym XF86AudioLowerVolume exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-volume 0 -5% #decrease sound volume
    bindsym XF86AudioMute exec --no-startup-id ${config.hardware.pulseaudio.package}/bin/pactl set-sink-mute 0 toggle # mute sound

    # Sreen brightness controls
    bindsym XF86MonBrightnessUp exec ${pkgs.light}/bin/light -A 10 # increase screen brightness
    bindsym XF86MonBrightnessDown exec ${pkgs.light}/bin/light -U 10 # decrease screen brightness

    # keybinding to lock screen
    bindsym Control+$mod+l exec fancy-sway-lock

    # reload the configuration file
    bindsym $mod+Shift+c reload

    # exit sway (logs you out of your wayland session)
    bindsym $mod+Shift+e exec ${pkgs.sway}/bin/swaynag -t warning -m 'Do you really want to exit sway?' -B 'Yes, exit sway' 'swaymsg exit'

    # screenshots
    bindsym --release $mod+Print exec ${pkgs.grim}/bin/grim - | ${processScreenshot}
    bindsym --release $mod+Shift+Print exec ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d)" - | ${processScreenshot}

    # resize window (you can also use the mouse for that)
    mode "resize" {
      # These bindings trigger as soon as you enter the resize mode

      # Pressing left will shrink the window’s width.
      bindsym h resize shrink width 10 px or 10 ppt
      bindsym Left resize shrink width 10 px or 10 ppt

      # Pressing down will grow the window’s height.
      bindsym j resize grow height 10 px or 10 ppt
      bindsym Down resize grow height 10 px or 10 ppt

      # Pressing up will shrink the window’s height.
      bindsym k resize shrink height 10 px or 10 ppt
      bindsym Up resize shrink height 10 px or 10 ppt

      # Pressing right will grow the window’s width.
      bindsym l resize grow width 10 px or 10 ppt
      bindsym Right resize grow width 10 px or 10 ppt

      # back to normal: Enter or Escape
      bindsym Return mode "default"
      bindsym Escape mode "default"
    }
    bindsym $mod+r mode "resize"

    # Start sway-bar to display a workspace bar
    bar {
      position bottom

      font ${cfg.desktop.sway.font.bar.name} ${toString cfg.desktop.sway.font.bar.size}

      colors {
        background #0C0C0C
        statusline #DBDBDB
        separator  #666666

        focused_workspace  #2F4A5E #173144 #DBDBDB
        active_workspace   #333333 #222222 #DBDBDB
        inactive_workspace #333333 #222222 #888888
        urgent_workspace   #2F343A #661A1A #DBDBDB
        binding_mode       #2F343A #661A1A #DBDBDB
      }
      status_command ${pkgs.i3status-rust}/bin/i3status-rs ${pkgs.writeText "i3status-config" statusBarConfig}
    }
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
    wifiInterface =
      mkOption {
        type = types.str;
        description = "Name of the wireless interface to display info in status bar;
  leave empty to not include in status bar";
        default = "";
        example = "wlp0s20f3";
      };
    showPower = mkOption {
      type = types.bool;
      description = "Include battery info in status bar";
      default = false;
    };
    terminal = mkOption {
      type = types.str;
      description = "Default terminal to run";
      default = "alacritty";
      example = "foot";
    };
    font = {
      title = {
        name = mkOption {
          type = types.str;
          description = "Name of the font to use for window titles";
          default = "pango:FuraMono Nerd Font Mono, DejaVu Sans Mono";
          example = "pango:DejaVu Sans Mono";
        };
        size = mkOption {
          type = types.number;
          description = "Size of the font to use for window titles";
          default = 10;
          example = 10;
        };
      };
      bar = {
        name = mkOption {
          type = types.str;
          description = "Name of the font to use for the status bar";
          default = "pango:FuraMono Nerd Font Mono, DejaVu Sans Mono";
          example = "pango:DejaVu Sans Mono";
        };
        size = mkOption {
          type = types.number;
          description = "Size of the font to use for the status bar";
          default = 8;
          example = 8;
        };
      };
      notifications = {
        name = mkOption {
          type = types.str;
          description = "Name of the font to use for notifications";
          default = "pango:FuraMono Nerd Font Mono, DejaVu Sans Mono";
          example = "pango:DejaVu Sans Mono";
        };
        size = mkOption {
          type = types.number;
          description = "Size of the font to use for notifications";
          default = 8;
          example = 8;
        };
      };
    };
  };

  config = mkIf cfg.desktop.sway.enable {
    # allow for running gnome things outside of gnome (like for using themes)
    programs.dconf.enable = true;
    #environment.pathsToLink = [ "/libexec" ];
    services = {
      xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
        };
        displayManager.defaultSession = "sway";
        layout = "us";
      };
    };

    environment.systemPackages = with pkgs; [
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
