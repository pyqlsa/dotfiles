#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

pushd "$(dirname "${0}")/.."
nix build .#nixosConfigurations.baseIso.config.system.build.isoImage
popd
