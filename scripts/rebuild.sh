#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

host=""
action=""

display_help() {
  echo "A helper script wrapping nixos-rebuild."
  echo
  echo "Usage: $(basename "${0}") [options...]" >&2
  echo
  echo "    -h, --help"
  echo "                          display this help text."
  echo "    -t, --target <hostname>"
  echo "                          host to target."
  echo "    -a, --action <action>"
  echo "                          action to take (e.g. dry-activate, test, boot, switch)."
}

if [[ $# -eq 0 ]]; then
  display_help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -t | --target)
      if [ $# -gt 1 ]; then
        host="${2}"
      else
        display_help
        exit 1
      fi
      shift 2
      ;;
    -a | --action)
      if [ $# -gt 1 ]; then
        action="${2}"
      else
        display_help
        exit 1
      fi
      shift 2
      ;;
    -h | --help)
      display_help
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: ${1}" >&2
      display_help
      exit 1
      ;;
  esac
done

[[ ${action} == "" ]] && echo "ERROR: specifying an action is required" && display_help && exit 1

pushd "$(dirname "${0}")/.."
if [ "${host}" == "" ]; then
  sudo nixos-rebuild --flake .# "${action}"
else
  nixos-rebuild --flake ".#${host}" --target-host "${host}" --sudo "${action}"
fi
popd
