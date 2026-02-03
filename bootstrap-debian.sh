#!/bin/env bash

# Abort script if any command fails
set -e

# Set environment variables. Variables in lines prepended with : can also be passed to the script
KERNEL_VERSION=5.10.160
DEBIAN_RELEASE="bookworm"
DEBIAN_COMPONENTS="main contrib non-free non-free-firmware"
DEBIAN_PACKAGES="systemd-resolved systemd-timesyncd firmware-linux-free sudo wpasupplicant ssh bluez gpg locales manpages man-db htop git python3 wget curl vim"

: "${WIFI_SSID:=SSID}"
: "${WIFI_PASSWORD:=PASSWORD}"
: "${SOVOL_HOSTNAME:=sovol06ace.local}"

# If installing additional debian packages, ensure image size is sufficiently large
: "${IMG_SIZE_MB:=1024}"
MNT_PATH=$(pwd)/tmp/mnt
DEBIAN_ROOT=$MNT_PATH/rootfs_debian
SOVOL_ROOT=$MNT_PATH/rootfs_sovol

# Create temporary directory
mkdir -p tmp
cd tmp

# Make a copy of the unpacked update image
if [[ ! -e firmware_update_debian ]]; then
    cp -a firmware_update_sovol firmware_update_debian
fi

# Create a clean rootfs and format as ext4
rm -f firmware_update_debian/Image/rootfs.img
dd if=/dev/zero of=firmware_update_debian/Image/rootfs.img bs=1M count=$IMG_SIZE_MB conv=fdatasync status=progress
mkfs.ext4 firmware_update_debian/Image/rootfs.img

# Create mount points and mount images
sudo mkdir -p mnt/rootfs_debian mnt/rootfs_sovol
sudo mount -o loop firmware_update_debian/Image/rootfs.img "$DEBIAN_ROOT"
sudo mount -o loop firmware_update_sovol/Image/rootfs.img "$SOVOL_ROOT"

# Bootstrap system
sudo debootstrap --foreign --arch=arm64 $DEBIAN_RELEASE "$DEBIAN_ROOT" https://deb.debian.org/debian
sudo chroot "$DEBIAN_ROOT" /debootstrap/debootstrap --second-stage

# Mount virtual filesystems to suppress warnings
sudo mount --bind /dev "$DEBIAN_ROOT"/dev
sudo mount --bind /dev/pts "$DEBIAN_ROOT"/dev/pts
sudo mount -t proc proc "$DEBIAN_ROOT"/proc
sudo mount -t sysfs sys "$DEBIAN_ROOT"/sys

# Need to update for some reason to avoid errors on bookworm and bullseye
sudo chroot "$DEBIAN_ROOT" apt update

# Add Debian sources and update
sudo chroot "$DEBIAN_ROOT" rm -f /etc/apt/sources.list  # Remove copied source list
sudo chroot "$DEBIAN_ROOT" bash -c "cat > /etc/apt/sources.list.d/debian.sources << EOF
Types: deb
URIs: https://deb.debian.org/debian
Suites: $DEBIAN_RELEASE $DEBIAN_RELEASE-updates
Components: $DEBIAN_COMPONENTS
Enabled: yes
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: $DEBIAN_RELEASE-security
Components: $DEBIAN_COMPONENTS
Enabled: yes
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
"
sudo chroot "$DEBIAN_ROOT" apt update

# Install additional packages
sudo chroot "$DEBIAN_ROOT" apt install --yes $DEBIAN_PACKAGES

# Add user sovol
sudo chroot "$DEBIAN_ROOT" useradd sovol -m -d /home/sovol -G sudo,tty,dialout,video -s /bin/bash
sudo chroot "$DEBIAN_ROOT" bash -c "echo 'sovol:sovol' | chpasswd"  # Set default password to sovol

# Create directory for additional kernel modules
sudo chroot "$DEBIAN_ROOT" mkdir -p /lib/modules/$KERNEL_VERSION/extra

# Copy services, configuration files, kernel modules etc from the official sovol image
sudo cp -a "$SOVOL_ROOT"/lib/modules/{RTL8189FS,rtk_btusb,hci_uart,bcmdhd}.ko "$DEBIAN_ROOT"/lib/modules/$KERNEL_VERSION/extra
sudo cp -a "$SOVOL_ROOT"/lib/systemd/system/{resize-all,usbdevice,makerbase-automount@}.service "$DEBIAN_ROOT"/lib/systemd/system
sudo cp -a "$SOVOL_ROOT"/etc/systemd/system/{klipper-mcu,makerbase-client}.service "$DEBIAN_ROOT"/etc/systemd/system

sudo cp -a "$SOVOL_ROOT"/etc/fstab "$DEBIAN_ROOT"/etc/fstab
sudo cp -a "$SOVOL_ROOT"/etc/sudoers "$DEBIAN_ROOT"/etc/sudoers
sudo cp -a "$SOVOL_ROOT"/usr/bin/{makerbase-automount,disk-helper,resize-helper,usbdevice} "$DEBIAN_ROOT"/usr/bin
sudo cp -a "$SOVOL_ROOT"/usr/local/bin/klipper_mcu "$DEBIAN_ROOT"/usr/local/bin

sudo cp -a "$SOVOL_ROOT"/home/sovol/{access,printer_data} "$DEBIAN_ROOT"/home/sovol
sudo cp -a "$SOVOL_ROOT"/home/sovol/printer_data/config/mainsail.cfg "$DEBIAN_ROOT"/printer_data
sudo cp -a "$SOVOL_ROOT"/packages/rktoolkit/rktoolkit_1.0.0-1_arm64.deb "$DEBIAN_ROOT"/opt

# Set language in default UI to English
sudo bash -c "echo 'languange=en' > $DEBIAN_ROOT/home/sovol/printer_data/build/config.cfg"

# Force ownership of everything under /home/sovol to new user 'sovol'
sudo chroot "$DEBIAN_ROOT" chown -R sovol:sovol /home/sovol

# Make ownership exceptions for files related to screen UI
sudo chroot "$DEBIAN_ROOT" chown root:root /home/sovol/printer_data/config/{skiprs_conf.ini,skiprs_conf.ini.bak}

# Set hostname and populate /etc/hosts with some default addresses
sudo chroot "$DEBIAN_ROOT" bash -c "echo $SOVOL_HOSTNAME > /etc/hostname"
sudo chroot "$DEBIAN_ROOT" bash -c "cat > /etc/hosts << EOF
# Standard host addresses
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
# This host address
127.0.1.1 $SOVOL_HOSTNAME
EOF
"

# Install rktoolkit for USB-C debugging through adbd
sudo chroot "$DEBIAN_ROOT" dpkg -i /opt/rktoolkit_1.0.0-1_arm64.deb

# Load kernel modules for wifi and bluetooth
sudo chroot "$DEBIAN_ROOT" bash -c "/sbin/depmod $KERNEL_VERSION"
sudo chroot "$DEBIAN_ROOT" bash -c "cat > /etc/modules-load.d/wifibt.conf << EOF
# Load wifi- and bluetooth modules
8189fs
rtk_btusb
hci_uart
bcmdhd
EOF
"

# Configure DHCP for interface wlan0
sudo chroot "$DEBIAN_ROOT" bash -c "cat > /etc/systemd/network/25-wireless.network << EOF
[Match]
Name=wlan0

[Network]
DHCP=yes
EOF
"

# Configure wpa supplicant to connect to WIFI
sudo chroot "$DEBIAN_ROOT" bash -c "cat > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf << EOF
ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid=\"$WIFI_SSID\"
    psk=\"$WIFI_PASSWORD\"
    key_mgmt=WPA-PSK
}
EOF
"
sudo chroot "$DEBIAN_ROOT" systemctl enable wpa_supplicant@wlan0

# Enable some useful system services
sudo chroot "$DEBIAN_ROOT" systemctl enable systemd-networkd  # Networking
sudo chroot "$DEBIAN_ROOT" systemctl enable systemd-resolved  # DNS
sudo chroot "$DEBIAN_ROOT" systemctl enable systemd-timesyncd  # NTP
sudo chroot "$DEBIAN_ROOT" systemctl enable ssh  # Remote access over network

# Enable sovol specific services
sudo chroot "$DEBIAN_ROOT" systemctl enable resize-all  # Resizes image to emmc
sudo chroot "$DEBIAN_ROOT" systemctl enable usbdevice  # Remote access over USB-C

# Finalize by unmounting everything
sudo umount -R "$DEBIAN_ROOT" "$SOVOL_ROOT"
