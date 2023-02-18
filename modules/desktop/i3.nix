{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.sys;
  i3StatusBarConfig = ''
    general {
      output_format = i3bar
      colors = true
      color_good = "#2267a5"
      color_degraded = "#8c7f22"
      color_bad = "#be2422"
      interval = 1
    }
    order += "cpu_usage"
    order += "memory"
    order += "disk /"
    order += "volume master"
    ${optionalString (cfg.desktop.i3.wifiInterface != "") ''
      order += "wireless ${cfg.desktop.i3.wifiInterface}"
    ''}
    ${optionalString (cfg.desktop.i3.showPower) ''
      order += "battery 0"
    ''}
    order += "tztime local"
    cpu_usage {
      format = " CPU: %usage "
    }
    memory {
      format = " Mem: %used "
      threshold_degraded = "10%"
      format_degraded = "MEMORY: %free"
    }
    disk "/" {
      format = " Disk: %free (%avail) / %total "
    }
    volume master {
      format = " Vol: %volume "
      device = "default"
      mixer = "Master"
      mixer_idx = 0
    }
    ${optionalString (cfg.desktop.i3.wifiInterface != "") ''
      wireless ${cfg.desktop.i3.wifiInterface} {
        format_up = " WiFi: %ip %quality %essid %bitrate "
        format_down = " WiFi: (/) "
      }''}
    ${optionalString (cfg.desktop.i3.showPower) ''
      battery 0 {
        format = " Power: %status %percentage %remaining left "
        path = "/sys/class/power_supply/BAT0/uevent"
        low_threshold = 20
      }''}
    tztime local {
      format = " Date: %m/%d/%y  Time: %H:%M "
    }
  '';

  fancyLock = "${pkgs.scrot}/bin/scrot -o /tmp/lock.png && ${pkgs.imagemagick}/bin/convert /tmp/lock.png -scale 10% -scale 1000% /tmp/lock.png && ${pkgs.i3lock}/bin/i3lock 0 -i /tmp/lock.png";
in
{
  options.sys.desktop.i3 = {
    enable = mkEnableOption (lib.mdDoc "i3 desktop");
    background = mkOption {
      type = types.package;
      description = "Background image to use";
      default = cfg.desktop.wallpaper;
    };
    wifiInterface = mkOption {
      type = types.str;
      description = "Name of the wireless interface to display info in status bar; leave empty to not include in status bar";
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
      example = "i3-sensible-terminal";
    };
    displayCommand = mkOption {
      type = types.str;
      description = "Display configuration command to run on startup";
      default = "${pkgs.xorg.xrandr}/bin/xrandr --auto";
      example = "${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --auto --right-of DP-2";
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
    };
  };

  config = mkIf cfg.desktop.i3.enable {
    # allow for running gnome things outside of gnome (like for using themes)
    programs.dconf.enable = true;
    environment.pathsToLink = [ "/libexec" ];
    hardware.acpilight.enable = true;
    services = {
      xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
        };
        displayManager.defaultSession = "none+i3";
        displayManager.lightdm = {
          enable = true;
          background = cfg.desktop.i3.background;
          greeters.slick = {
            enable = true;
            extraConfig = ''
              draw-grid=true
              show-hostname=true
              show-keyboard=true
              show-a11y=true
              show-power=true
              show-clock=true
              show-quit=true
            '';
          };
        };
        layout = "us";
        windowManager.i3 = {
          enable = true;
          extraPackages = with pkgs; [
            brightnessctl
            dmenu
            dunst
            feh
            i3status
            i3lock
            i3blocks
            imagemagick
            networkmanagerapplet
            networkmanager_dmenu
            scrot
            xautolock
          ];
          extraSessionCommands = ''
            ${pkgs.dunst}/bin/dunst &
            ${optionalString config.networking.networkmanager.enable "${pkgs.networkmanagerapplet}/bin/nm-applet &"}
            ${optionalString config.hardware.bluetooth.enable "${pkgs.blueman}/bin/blueman-applet &"}
          '';
          configFile = pkgs.writeText "i3.cfg" ''
            # i3 config file (v4)
            set $mod Mod1

            # Font for window titles. Will also be used by the bar unless a different font
            # is used in the bar {} block below.
            font ${cfg.desktop.i3.font.title.name} ${toString cfg.desktop.i3.font.title.size}
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

            # Use Mouse+$mod to drag floating windows to their wanted position
            floating_modifier $mod

            # start a terminal
            #bindsym $mod+Return exec "${pkgs.i3}/bin/i3-sensible-terminal"
            bindsym $mod+Return exec "${cfg.desktop.i3.terminal}"

            # kill focused window
            bindsym $mod+Shift+q kill

            # start dmenu (a program launcher)
            bindsym $mod+d exec "${pkgs.dmenu}/bin/dmenu_run"

            # There also is the (new) i3-dmenu-desktop which only displays applications
            # shipping a .desktop file. It is a wrapper around dmenu, so you need that
            # installed.
            # bindsym $mod+d exec --no-startup-id "${pkgs.i3}/bin/i3-dmenu-desktop"

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
            bindsym XF86MonBrightnessUp exec ${pkgs.acpilight}/bin/xbacklight -inc 10 # increase screen brightness
            bindsym XF86MonBrightnessDown exec ${pkgs.acpilight}/bin/xbacklight -dec 10 # decrease screen brightness

            # multimedia keys
            #bindsym XF86AudioPlay  exec "mpc toggle"
            #bindsym XF86AudioStop  exec "mpc stop"
            #bindsym XF86AudioNext  exec "mpc next"
            #bindsym XF86AudioPrev  exec "mpc prev"
            #bindsym XF86AudioPause exec "mpc pause"

            # keybinding to lock screen
            #bindsym Control+$mod+l exec "${pkgs.i3lock}/bin/i3lock -c 000000"
            bindsym Control+$mod+l exec "${fancyLock}"

            # auto lock the screen
            # need to solve media playing detection before continuing to use
            #exec "${pkgs.xautolock}/bin/xautolock -detectsleep -time 8 -locker \"${fancyLock}\""

            # reload the configuration file
            bindsym $mod+Shift+c reload

            # restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
            bindsym $mod+Shift+r restart

            # exit i3 (logs you out of your X session)
            bindsym $mod+Shift+e exec "${pkgs.i3}/bin/i3-nagbar -t warning -m 'Do you really want to exit i3?' -b 'Yes, exit i3' 'i3-msg exit'"
            bindsym --release $mod+z exec "${pkgs.scrot}/bin/scrot -s ~/screenshots/screenshot-`date +%Y-%m-%d-%H-%M-%s`.png"

            # display configuration
            exec_always --no-startup-id "${cfg.desktop.i3.displayCommand}"
            exec_always --no-startup-id "${pkgs.feh}/bin/feh --bg-fill ${cfg.desktop.i3.background} &"

            # resize window (you can also use the mouse for that)
            mode "resize" {
              # These bindings trigger as soon as you enter the resize mode
              # Pressing left will shrink the window’s width.
              # Pressing right will grow the window’s width.
              # Pressing up will shrink the window’s height.
              # Pressing down will grow the window’s height.
              bindsym h resize shrink width 10 px or 10 ppt
              bindsym j resize grow height 10 px or 10 ppt
              bindsym k resize shrink height 10 px or 10 ppt
              bindsym l resize grow width 10 px or 10 ppt
              # same bindings, but for the arrow keys
              bindsym Left resize shrink width 10 px or 10 ppt
              bindsym Down resize grow height 10 px or 10 ppt
              bindsym Up resize shrink height 10 px or 10 ppt
              bindsym Right resize grow width 10 px or 10 ppt
              # back to normal: Enter or Escape
              bindsym Return mode "default"
              bindsym Escape mode "default"
            }
            bindsym $mod+r mode "resize"

            # Start i3bar to display a workspace bar (plus the system information i3status
            # finds out, if available)
            bar {
              #font termsyn:monospace 8
              font ${cfg.desktop.i3.font.bar.name} ${toString cfg.desktop.i3.font.bar.size}

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
              status_command ${pkgs.i3status}/bin/i3status -c ${
              pkgs.writeText "i3status-config" i3StatusBarConfig
            }
            }
          '';
        };
      };
    };
  };
}
