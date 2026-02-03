#!/usr/bin/env bash

# Abort script if any command fails
set -e

# Set environment variables
SOVOL_ADDRESS=$1
if [[ ! $SOVOL_ADDRESS ]]; then
    echo "Please provide printer ip address, i.e. run script as: ./install-klipper.sh SOVOL_ADDRESS"
    exit 1
fi

CWD=$(pwd)
MNT_PATH=$CWD/tmp/mnt
SOVOL_ROOT=$MNT_PATH/rootfs_sovol

sudo mount -o loop tmp/firmware_update_sovol/Image/rootfs.img "$SOVOL_ROOT"
sudo mount --bind /dev "$SOVOL_ROOT"/dev

# Obtain list of deleted and modified files made by sovol to klipper
GIT_STATUS_OUT=$(sudo chroot "$SOVOL_ROOT" su -s bin/bash sovol -c "cd ~/klipper && git status")
DELETED_FILES=$(echo "$GIT_STATUS_OUT" | grep "deleted" | awk '{print $2}')
MODIFIED_FILES=$(echo "$GIT_STATUS_OUT" | grep "modified" | awk '{print $2}')
UNTRACKED_FILES="klippy/extras/hx711.py"

# Download Klipper to printer single-board computer
echo "Downloading klipper on printer..."
ssh -tt sovol@$SOVOL_ADDRESS "
    set -e
    rm -rf klipper
    git clone https://github.com/Klipper3d/klipper.git
    cd klipper
    git checkout 12cd1d9e
"

cd "$SOVOL_ROOT"/home/sovol/klipper

# Upload Klipper files tuned for sovol ace printers
echo "Uploading Sovol Klipper files to printer:"
echo "Creating tarball on host"
tar -cvf "$CWD"/tmp/klipper_sovol_files.tar $MODIFIED_FILES $UNTRACKED_FILES 
echo "Uploading tarball to printer SBC"
scp "$CWD"/tmp/klipper_sovol_files.tar sovol@$SOVOL_ADDRESS:
echo "Extracting files on printer SBC"
ssh -tt sovol@$SOVOL_ADDRESS "tar -xvf klipper_sovol_files.tar -C klipper"

# Install Klipper build dependencies
echo "Installing Klipper..."
ssh -tt sovol@$SOVOL_ADDRESS "
    set -e
    sudo apt install --yes python3-venv python3-dev pkg-config libffi-dev build-essential libncurses-dev libusb-dev
    python3 -m venv /home/sovol/klippy-env
    /home/sovol/klippy-env/bin/pip install -r /home/sovol/klipper/scripts/klippy-requirements.txt
"

echo "Setting MCU id"
MCU_ID=$(ssh sovol@$SOVOL_ADDRESS 'ls /dev/serial/by-id')
ssh -tt sovol@$SOVOL_ADDRESS "
    cat > /home/sovol/printer_data/config/MCU_ID.cfg <<EOF
[mcu extra_mcu]
serial:/dev/serial/by-id/$MCU_ID
restart_method: command
EOF
"

echo "Enabling Klipper services"
adb push "$SOVOL_ROOT"/etc/systemd/system/klipper.service /etc/systemd/system
ssh -tt sovol@$SOVOL_ADDRESS "
    sudo systemctl enable klipper klipper-mcu
"

cd "$CWD"
sudo umount -R "$SOVOL_ROOT"
