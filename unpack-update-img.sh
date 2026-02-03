#!/bin/env bash

# Abort script if any command fails
set -e

# Read update image
UPDATE_IMG_PATH=$1

if [[ ! $UPDATE_IMG_PATH ]]; then
    echo "Please provide path to update image, i.e runscript as: ./unpack-update-img.sh path_to_update_image"
    exit 1
fi

# Set environment variables
RKDEV_TOOLS_URL=https://raw.githubusercontent.com/vicharak-in/rockchip-linux-tools/master/linux/Linux_Pack_Firmware/rockdev

# Create a temporary working directory
mkdir -p tmp
cd tmp

# Download Rockchip image tools
echo "Downloading rockchip tools"
mkdir -p bin
wget $RKDEV_TOOLS_URL/afptool -O bin/rk_afptool
wget $RKDEV_TOOLS_URL/rkImageMaker -O bin/rk_image_maker
chmod +x bin/rk_image_maker bin/rk_afptool

# Unpack the update image
echo "Unpacking update image"
mkdir -p firmware_update_sovol
bin/rk_image_maker -unpack ../$UPDATE_IMG_PATH firmware_update_sovol
bin/rk_afptool -unpack firmware_update_sovol/firmware.img firmware_update_sovol
cd ..
