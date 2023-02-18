#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

pushd "$(dirname "${0}")/.."
#nixos-rebuild build-vm --flake .#
nix run .#nixosConfigurations."${HOSTNAME}".config.system.build.vm
popd
