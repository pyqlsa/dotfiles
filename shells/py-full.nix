{ pkgs ? import <nixpkgs> { }
, python-full ? pkgs.python3Full
}:
(pkgs.buildFHSUserEnv {
  name = "py-full";
  targetPkgs = pkgs: (with pkgs; [
    python-full
  ]);
  runScript = "zsh";
}).env
