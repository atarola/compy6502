#!/bin/bash
set -e
DEVICE=$(sudo blkid -L RPI-RP2)
sudo umount /mnt/pico 2>/dev/null || true
sudo mount -o uid=$(id -u),gid=$(id -g) "$DEVICE" /mnt/pico
~/.cargo/bin/elf2uf2-rs "$1" /mnt/pico/flash.uf2
sync
sudo umount /mnt/pico
echo "Press reset"
