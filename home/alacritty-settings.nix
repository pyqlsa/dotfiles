{ font-name, ... }: {
  env = {
    "TERM" = "xterm-256color";
  };
  window = {
    opacity = 0.95;
    padding.x = 5;
    padding.y = 5;
    decorations = "Full"; # or 'None'
  };
  font = {
    normal = {
      family = font-name;
      style = "Regular";
    };
    bold = {
      family = font-name;
      style = "Bold";
    };
    italic = {
      family = font-name;
      style = "Italic";
    };
    size = 7;
  };
  #cursor.style = "Beam";
  colors = {
    # Default colors
    primary = {
      background = "0x161616";
      foreground = "0xf2f4f8";
    };
    # Normal colors
    normal = {
      black = "0x282828";
      red = "0xee5396";
      green = "0x25be6a";
      yellow = "0x08bdba";
      blue = "0x78a9ff";
      magenta = "0xbe95ff";
      cyan = "0x33b1ff";
      white = "0xdfdfe0";
    };
    # Bright colors
    bright = {
      black = "0x484848";
      red = "0xf16da6";
      green = "0x46c880";
      yellow = "0x2dc7c4";
      blue = "0x8cb6ff";
      magenta = "0xc8a5ff";
      cyan = "0x52bdff";
      white = "0xe4e4e5";
    };
    indexed_colors = [
      {
        index = 16;
        color = "0x3ddbd9";
      }
      {
        index = 17;
        color = "0xff7eb6";
      }
    ];
  };
}
