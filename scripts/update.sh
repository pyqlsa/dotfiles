#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

nix flake update
