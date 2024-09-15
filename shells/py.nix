{ pkgs ? import <nixpkgs> { }
, python ? pkgs.python3
, name ? "python"
}:
(pkgs.buildFHSUserEnv {
  name = "python";
  targetPkgs = pkgs: (with pkgs; [
    python
  ]);
  runScript = "zsh";
}).env
