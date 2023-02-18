#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

file=""
disk=""
force="false"

display_help() {
  echo "A helper script for making a bootable usb from an iso."
  echo
  echo "Usage: $(basename "{0}") [options...]" >&2
  echo
  echo "    -h, --help"
  echo "                          display this help text."
  echo "    -f, --file <file>"
  echo "                          path to iso file to write to device."
  echo "    -d, --disk <device>"
  echo "                          disk to partition."
  echo "    --force"
  echo "                          don't prompt for confirmation before writing."
}

if [[ $# -eq 0 ]]; then
  display_help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -f | --file)
      if [ $# -gt 1 ]; then
        file="$(realpath "${2}")"
      else
        display_help
        exit 1
      fi
      shift 2
      ;;
    -d | --disk)
      if [ $# -gt 1 ]; then
        disk="${2}"
      else
        display_help
        exit 1
      fi
      shift 2
      ;;
    --force)
      force="true"
      shift 1
      ;;
    *)
      echo "ERROR: Unknown option: ${1}" >&2
      display_help
      exit 1
      ;;
  esac
done

[[ ! -e "${file}" ]] && echo "ERROR: I need an iso file!" && display_help && exit 1
[[ "${disk}" == "" ]] && echo "ERROR: I need a disk!" && display_help && exit 1
[[ ! -b "${disk}" ]] && echo "ERROR: ${disk} is not a block device!" && display_help && exit 1

echo "going to write ${file} to ${disk}"
if [ "${force}" != "true" ]; then
  echo "press any key to contine or Ctrl+c to abort..."
  read
fi

echo "freshening target disk: ${disk}"
sudo dd if=/dev/zero of="${disk}" bs=4M count=100 conv=fsync oflag=direct status=progress
echo
echo "writing iso..."
echo
sudo dd bs=4M if="${file}" of="${disk}" conv=fsync oflag=direct status=progress
echo
echo "complete!"
