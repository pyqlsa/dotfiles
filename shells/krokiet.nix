{ pkgs ? import <nixpkgs> { }
, czkawka ? pkgs.czkawka-full
, name ? "czkawka"
}:
let
  libPath = with pkgs; lib.makeLibraryPath [
    libGL
    libxkbcommon
    wayland
  ];
in
pkgs.mkShell {
  LD_LIBRARY_PATH = libPath;
}
