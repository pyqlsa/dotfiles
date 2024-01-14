#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

pushd "$(dirname "${0}")/.."
if [ "${1:-}" == "" ]; then
  sudo nixos-rebuild switch --flake .#
else
  host="${1}"
  nixos-rebuild --flake ".#${host}" --target-host "${host}" --use-remote-sudo switch
fi
popd
