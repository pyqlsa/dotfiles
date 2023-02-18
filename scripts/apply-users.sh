#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

pushd "$(dirname "${0}")/.."
nix build .#homeConfigurations.pyqlsa.activationPackage
./result/activate
popd
