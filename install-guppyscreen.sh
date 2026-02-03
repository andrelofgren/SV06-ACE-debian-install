#!/bin/env bash

# Abort on failure
set -e

# Install guppy installation-script dependencies
sudo apt install jq

# Download installation script
wget https://raw.githubusercontent.com/probielodan/guppyscreen/main/scripts/installer-deb.sh

# Make a few modifications to script:
# 1) Don't start Guppy service immediately after installation since user sovol may not yet belong to required groups
sed -r -i "/^[ \t]+restart_services/s/^/#/" installer-deb.sh

# 2) Scripts disables KlipperScreen and will throw an error if not installed, so comment out if not installed
if ! systemctl status KlipperScreen > /dev/null 2>&1; then
	sed -i "/^[[:space:]]*sudo systemctl disable KlipperScreen.service[[:space:]]*$/s/^/#/" installer-deb.sh
fi

# 3) Not strictly need due to 1), but for sake of consistency replace _service_ with _systemctl_
sed -i "s/service guppyscreen restart/systemctl restart guppyscreen/" installer-deb.sh

# Run installation script
bash installer-deb.sh

# GuppyScreen will be displayed upside-down by default on SV06 ACE, so rotate by 180 degrees (0->0, 1->90, 2->180, 3->270)
jq ".display_rotate = 2" ~/guppyscreen/guppyconfig.json  > ~/guppyscreen/guppyconfig_tmp.json
mv ~/guppyscreen/guppyconfig_tmp.json ~/guppyscreen/guppyconfig.json

# Grant user sovol permission to read touch input and manage networks
sudo usermod -aG input,netdev sovol

# Disable Sovol's proprietary UI
sudo systemctl disable makerbase-client

echo "Reboot for changes to take effect"
