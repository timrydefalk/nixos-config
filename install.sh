#!/usr/bin/bash
[[ $(id -u) != 0 ]] && { echo "Execute as root"; exit 1; }
[[ ! -f ./configuration.nix ]] && {echo "No configuration.nix in current directory"; exit 1; }
[[ -z "$1" ]] && { echo "Did not receive disk." ; exit 1; }

disk=$1

echo "Removing existing volumes"
wipefs -a ${disk}

echo "Creating volumes"
parted ${disk} -- mklabel gpt
parted ${disk} -- mkpart primary 512MiB -8GiB
parted ${disk} -- mkpart primary linux-swap -8GiB 100%
parted ${disk} -- mkpart ESP fat32 1MiB 512MiB
parted ${disk} -- set 3 esp on

echo "Formatting volumes"
mkfs.ext4 -L nixos ${disk}1
mkswap -L swap ${disk}2
mkfs.fat -F 32 -n boot ${disk}3

echo "Mounting volumes"
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon ${disk}2

echo "Generating NixOS configuration"
nixos-generate-config --root /mnt

echo "Replacing"
rm /mnt/etc/nixos/configuration.nix
cp ./configuration.nix /mnt/etc/nixos/configuration.nix

echo "Initiating installation"
nixos-install
