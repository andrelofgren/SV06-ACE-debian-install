#!/bin/env bash

# Abort script if any command fails
set -e

# Set environment variables
RKDEV_TOOLS_URL=https://raw.githubusercontent.com/vicharak-in/rockchip-linux-tools/master/linux/Linux_Pack_Firmware/rockdev

# Create a temporary working directory
mkdir -p tmp
cd tmp

# Download and install Rockchip image tools if not already installed
mkdir -p bin
if [[ ! -f bin/rk_afptool ]]; then
    echo "Downloading afptool"
    wget $RKDEV_TOOLS_URL/afptool -O bin/rk_afptool
fi

if [[ ! -f bin/rk_image_maker ]]; then
    echo "Downloading rkImageMaker"
    wget $RKDEV_TOOLS_URL/rkImageMaker -O bin/rk_image_maker
fi

chmod +x bin/rk_image_maker bin/rk_afptool

# Packing new update image
cd firmware_update_debian
cp -f MiniLoaderAll.bin parameter.txt Image
../bin/rk_afptool -pack ./ update.img
../bin/rk_image_maker -RK3308 MiniLoaderAll.bin update.img ../../firmware_update_debian.img
cd ../..
echo "Debian update image successfully written to firmware_update_debian.img"
