{ pkgs ? import <nixpkgs> { }
, python ? pkgs.python3
, name ? "python"
}:
(pkgs.buildFHSEnv {
  name = "python";
  targetPkgs = pkgs: (with pkgs; [
    python
  ]);
  runScript = "zsh";
}).env
