#!/usr/bin/env bash
set -e
echo Building ISO...
nix build path:.#nixosConfigurations.hatcher.config.system.build.isoImage
du -h result/iso/*
echo Select disk to write ISO to:
lsblk
read mydisk
sudo popsicle result/iso/chicken-*.iso $mydisk
