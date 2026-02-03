#!/bin/env bash

# Abort script if any command fails
set -e

# Set environment variables
PYVENV_DIR=$(pwd)/tmp/gdown_venv
RKDEV_TOOLS_URL=https://raw.githubusercontent.com/vicharak-in/rockchip-linux-tools/master/linux/Linux_Pack_Firmware/rockdev

echo "1) SOVOL SV06 ACE"
echo "2) SOVOL SV06 PLUS ACE"
echo -n "Select printer type (1, or 2): "
read PRINTER_TYPE_ID

case $PRINTER_TYPE_ID in
    1)
        KLP_IMG=KLP_IMG_sovol_V002.4_20241016_Release.7z
        GFILE_ID=1t2_03igAqScT5OzhM2XngovkdaFNezcw
        PRINTER_TYPE="SOVOL SV06 ACE"
        ;;
    2)
        KLP_IMG=KLP_IMG_SV06_PLUS_ACE_V004.2_20241224_Release.7z
        GFILE_ID=1JqItU3ocVFLEutPSgkyjmiHI0lzDTp1N
        PRINTER_TYPE="SOVOL SV06 PLUS ACE"
        ;;
    *)
        echo "Invalid printer type $PRINTER_TYPE"
        exit 1
        ;;
esac
echo "Downloading update image for $PRINTER_TYPE"

# Create temporary directory
mkdir -p tmp
cd tmp

# Create a python environment for downloading Sovol image from Google drive
python3 -m venv $PYVENV_DIR
source $PYVENV_DIR/bin/activate
pip install gdown

# Download and extract update image
gdown $GFILE_ID 
echo "Extracting..."
7z x $KLP_IMG -o..

echo "Update image was successfully downloaded and extracted!"
cd ..
