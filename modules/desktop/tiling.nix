{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.sys;
  statusBarConfig = ''
    ${lib.strings.concatMapStrings (d: ''
        [[block]]
        block = "disk_space"
        path = "${d}"
        interval = 20
        format = " $icon (${d}) Free $available / $total "
        warning = 80.0
        alert = 20.0
        info_type = "available"
        alert_unit = "GB"
        [[block.click]]
        button = "right"
        update = true

      '')
      cfg.desktop.tiling.bar.disks}
    [[block]]
    block = "memory"
    format = " $icon $mem_used "
    interval = 5
    warning_mem = 70
    critical_mem = 90

    [[block]]
    block = "cpu"
    format = " $icon $utilization "
    interval = 1

    [[block]]
    block = "net"
    format = " $icon {$signal_strength $ssid $frequency|Wired connection} via $device "

    [[block]]
    block = "battery"
    format = " $icon $percentage {$time |}"
    missing_format = ""

    [[block]]
    block = "sound"
    format = " {$output_description |}({$volume|mute}) "

    [[block]]
    block = "time"
    interval = 5
    format = " $timestamp.datetime(f:'%a %b %d %H:%M %Z %Y') "
  '';
  styleConfig = ''
    # --- Style ---
    # Font
    font ${cfg.desktop.tiling.font.title.name} ${toString cfg.desktop.tiling.font.title.size}
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
  '';
  barBlockConfig = ''
    # --- Bar ---
    bar {
      position bottom

      font ${cfg.desktop.tiling.font.bar.name} ${toString cfg.desktop.tiling.font.bar.size}

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
  resizeBlockConfig = ''
    # --- Resize ---
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
  '';
in
{
  options.sys.desktop.tiling = {
    background = mkOption {
      type = types.package;
      description = "Background image to use";
      default = cfg.desktop.wallpaper;
    };
    bar = {
      disks = mkOption {
        type = with types; listOf str;
        description = "Paths to report disk space in status bar";
        default = [ "/" ];
        example = [ "/" "/data" ];
      };
    };
    terminal = mkOption {
      type = types.str;
      description = "Default terminal to run";
      default = "alacritty";
      example = "foot";
    };
    displayCommand = mkOption {
      type = types.str;
      description = "Display configuration command to run on startup";
      default = "${pkgs.xorg.xrandr}/bin/xrandr --auto";
      example = "${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --auto --right-of DP-2";
    };
    displayConfig = mkOption {
      type = types.str;
      description = "Display configuration block to insert into configuration";
      default = "";
      example = ''
        output DP-1 position 0 0
        output DP-2 position 2560 0
      '';
    };
    inputConfig = mkOption {
      type = types.str;
      description = "Input configuration block to insert into configuration";
      default = "";
      example = ''
        input 2362:628:PIXA3854:00_093A:0274_Touchpad {
          left_handed enabled
          tap enabled
          natural_scroll disabled
          dwt enabled
          accel_profile "flat" # disable mouse acceleration (enabled by default; to set it manually, use "adaptive" instead of "flat")
          pointer_accel 0.5 # set mouse sensitivity (between -1 and 1)
        }
      '';
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
    styleConfig = mkOption {
      type = types.str;
      description = "Common style between tiling window managers";
      default = styleConfig;
      example = "";
    };
    barBlockConfig = mkOption {
      type = types.str;
      description = "Common bar config between tiling window managers";
      default = barBlockConfig;
      example = "";
    };
    resizeBlockConfig = mkOption {
      type = types.str;
      description = "Common resize config between tiling window managers";
      default = resizeBlockConfig;
      example = "";
    };
  };
}
