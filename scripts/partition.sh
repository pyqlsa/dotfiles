#!/usr/bin/env bash
set -eou pipefail
IFS=$' \n\t'

disk=""
encrypted="false"

# labels
bootLabel="boot"
rootLabel="nix-root"
encRootLabel="nix-enc-root"
swapLabel="swap"
encSwapLabel="nix-enc-swap"

display_help() {
  echo "A helper script for intial disk partitioning."
  echo
  echo "Usage: $(basename "{0}") [options...]" >&2
  echo
  echo "    -h, --help"
  echo "                          display this help text."
  echo "    -d, --disk <device>"
  echo "                          disk to partition."
  echo "    -e, --enc"
  echo "                          encrypt the disk."
}

if [[ $# -eq 0 ]]; then
  display_help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -d | --disk)
      if [ $# -gt 1 ]; then
        disk="${2}"
      else
        display_help
        exit 1
      fi
      shift 2
      ;;
    -e | --enc)
      encrypted="true"
      shift 1
      ;;
    *)
      echo "ERROR: Unknown option: ${1}" >&2
      display_help
      exit 1
      ;;
  esac
done

[[ "${disk}" == "" ]] && echo "ERROR: I need a disk!" && display_help && exit 1
[[ ! -b "${disk}" ]] && echo "ERROR: ${disk} is not a block device!" && display_help && exit 1

echo "using disk: ${disk}"
echo

# determine swap size
memtotalk=$(awk '/^MemTotal:/{print $2}' /proc/meminfo);
memtotalg=$((${memtotalk} / 1024 / 1024))
echo "detected total memory: ${memtotalg}GB (${memtotalk}kB)"
echo

extramem=4
finalk=$((${memtotalk} + $((${extramem} * 1024 * 1024))))
finalg=$((${finalk} / 1024 / 1024))

echo "suggested swap size: ${finalg}GB (${finalk}kB)"
echo "enter desired swap size in GB (or press enter to take the suggested value)"
read swapSize

if [ "${swapSize}" == "" ]; then
  swapSize=${finalg}
fi
swapSize="${swapSize}GB"
echo "going to set swap to: ${swapSize}"
echo "press any key to contine or Ctrl+c to abort..."
read

# determine boot partition size
defaultBootSize="1024"
echo "suggested boot partition size: ${defaultBootSize}MB"
echo "enter desired boot partition size in MB (or press enter to take the suggested value)"
read bootPartSize
if [ "${bootPartSize}" == "" ]; then
  bootPartSize=${defaultBootSize}
fi
bootPartSize="${bootPartSize}MB"
echo "going to set boot partition size to: ${bootPartSize}"
echo "press any key to contine or Ctrl+c to abort..."
read

# now actually do stuff
echo "freshening target disk: ${disk}"
dd if=/dev/zero of="${disk}" bs=4M count=100 conv=fsync oflag=direct status=progress
echo

echo "paritioning: ${disk}"
parted "${disk}" -- mklabel gpt
parted "${disk}" -- mkpart primary "${bootPartSize}" "-${swapSize}"
parted "${disk}" -- mkpart primary linux-swap "-${swapSize}" 100%
parted "${disk}" -- mkpart ESP fat32 1MB "${bootPartSize}"
parted "${disk}" -- set 3 esp on
echo

# default partition naming; nvme, mmc, ...
bootPart="${disk}p3"
rootPart="${disk}p1"
swapPart="${disk}p2"

# adjust parition naming if: sata, virtual, ...
if [[ $(basename "${disk}") =~ [sv]d. ]]; then
  bootPart="${disk}3"
  rootPart="${disk}1"
  swapPart="${disk}2"
fi

rootVol="${rootPart}"
swapVol="${swapPart}"

if [ "${encrypted}" == "true" ]; then
  firstPass=""
  secondPass=""
  while [ "${firstPass}" == "" ] || [ "${secondPass}" == "" ] || [ "${firstPass}" != "${secondPass}" ]; do
    echo "enter passphrase for luks partitions..."
    echo "...must be not empty."
    echo "Passphrase:"
    read -s firstPass
    echo "Confirm Passphrase:"
    read -s secondPass
    if [ "${firstPass}" != "${secondPass}" ]; then
      echo "Passphrases don't match!"
    fi
    echo
  done

  luksRootName="enc"
  luksRoot="/dev/mapper/${luksRootName}"
  luksSwapName="encswap"
  luksSwap="/dev/mapper/${luksSwapName}"

  echo "setting up luks on: ${rootPart}"
  #cryptsetup --verify-passphrase -v luksFormat "${rootPart}"
  echo -n "${firstPass}" | cryptsetup -v luksFormat --type=luks2 --label="${encRootLabel}" "${rootPart}" -d -
  echo

  echo "opening luks volume from: ${rootPart}"
  #cryptsetup open "${rootPart}" "${luksRootName}"
  echo -n "${firstPass}" | cryptsetup open "${rootPart}" "${luksRootName}" -d -
  echo

  rootVol="${luksRoot}"
  swapVol="${luksSwap}"
fi


mkfs.vfat -n "${bootLabel}" "${bootPart}"
mkfs.btrfs -L "${rootLabel}" "${rootVol}"
mount -t btrfs "${rootVol}" /mnt

btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/log
umount /mnt

mount -o subvol=root,compress=zstd,noatime "${rootVol}" /mnt
mkdir /mnt/home
mount -o subvol=home,compress=zstd,noatime "${rootVol}" /mnt/home
mkdir /mnt/nix
mount -o subvol=nix,compress=zstd,noatime "${rootVol}" /mnt/nix
mkdir -p /mnt/var/log
mount -o subvol=log,compress=zstd,noatime "${rootVol}" /mnt/var/log

mkdir /mnt/boot
mount "${bootPart}" /mnt/boot


if [ "${encrypted}" == "true" ]; then
  echo "generating luks swap key"
  mkdir /mnt/root
  dd count=1 bs=512 if=/dev/urandom of=/mnt/root/swap.key
  chmod 0400 /mnt/root/swap.key
  chown 0:0 /mnt/root/swap.key

  echo "setting up luks swap on: ${swapPart}"
  #cryptsetup --verify-passphrase -v luksFormat "${swapPart}"
  echo -n "${firstPass}" | cryptsetup -v luksFormat --type=luks2 --label="${encSwapLabel}" "${swapPart}" -d -
  #cryptsetup luksAddKey "${swapPart}" /mnt/root/swap.key
  echo -n "${firstPass}" | cryptsetup luksAddKey "${swapPart}" /mnt/root/swap.key -d -
  echo

  echo "opening luks swap volume from: ${swapPart}"
  cryptsetup open "${swapPart}" "${luksSwapName}" --key-file /mnt/root/swap.key
  echo
fi

echo "creating swap on: ${swapVol}"
mkswap -L "${swapLabel}" "${swapVol}"
swapon "${swapVol}"
echo

echo "now we're ready to run 'nixos-generate-config --root /mnt'"
echo
echo "tidying of swap devices in /mnt/etc/nixos/hardware-configuration.nix may be required..."

# https://unix.stackexchange.com/questions/529047/is-there-a-way-to-have-hibernate-and-encrypted-swap-on-nixos

# Move the swapDevices configuration from /mnt/etc/nixos/hardware-configuration.nix to /mnt/etc/nixos/configuration.nix. Note: You'll need to repeat this step if you ever run nixos-generate-config again.
#
# Edit swapDevices in /mnt/etc/nixos/configuration.nix to enable encryption. Here's an example:
#
#swapDevices =
#[ {
#    device = "/dev/disk/by-uuid/..."; #This is already done for you. Leave as-is.
#    encrypted = {
#      enable = true;
#      keyFile = "/mnt-root/root/swap.key"; #Yes, /mnt-root is correct.
#      label = "..."; The name used with `cryptsetup` when unlocking the LUKS container. It can be whatever you want, ex "luksswap".
#      blkDev = "/dev/disk/by-uuid/[UUID of the LUKS partition]";
#    };
#  }
#];
#
# You can get the UUID of the LUKS partition with lsblk -o name,uuid.

# After generating a config and tidying as appropriate, we're ready for:
#  nixos-install
#  reboot
