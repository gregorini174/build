#!/bin/bash
set -e

echo "=== Armbian eMMC Setup ==="

# Определить eMMC (не SD карту)
ROOT_DEV=$(findmnt -n -o SOURCE /)
ROOT_BASE=$(echo $ROOT_DEV | sed 's/p[0-9]*$//')

if [ "$ROOT_BASE" = "/dev/mmcblk0" ]; then
    EMMC="/dev/mmcblk1"
else
    EMMC="/dev/mmcblk0"
fi

EMMC_PART="${EMMC}p1"
echo "eMMC device: $EMMC"

# Форматировать eMMC
wipefs -a $EMMC
parted $EMMC --script mklabel msdos mkpart primary ext4 2MiB 100%
mkfs.ext4 -F $EMMC_PART

# Копировать систему
mkdir -p /mnt/emmc
mount $EMMC_PART /mnt/emmc
rsync -a --exclude=/proc --exclude=/sys --exclude=/dev \
      --exclude=/tmp --exclude=/run --exclude=/mnt \
      / /mnt/emmc/

# Исправить UUID
EMMC_UUID=$(blkid -o value -s UUID $EMMC_PART)
sed -i "s/rootdev=UUID=.*/rootdev=UUID=${EMMC_UUID}/" /mnt/emmc/boot/armbianEnv.txt

sync
umount /mnt/emmc

echo "=== Готово! Перезагрузитесь с SD картой ==="
