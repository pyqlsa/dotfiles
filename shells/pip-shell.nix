{ pkgs ? import <nixpkgs> { } }:
(pkgs.buildFHSUserEnv {
  name = "pipzone";
  targetPkgs = pkgs: (with pkgs; [
    (python311.withPackages (ps:
      with ps; [
        pip
        setuptools
        virtualenv
      ]))
  ]);
  runScript = "zsh";
}).env
