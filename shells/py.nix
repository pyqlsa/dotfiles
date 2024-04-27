{ pkgs ? import <nixpkgs> { }
, python-basic ? pkgs.python3
}:
(pkgs.buildFHSUserEnv {
  name = "py";
  targetPkgs = pkgs: (with pkgs; [
    python-basic
  ]);
  runScript = "zsh";
}).env
