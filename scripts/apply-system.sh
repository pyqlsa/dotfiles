#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

pushd "$(dirname "${0}")/.."
sudo nixos-rebuild switch --flake .#
popd
