# SV06 ACE Debian Install
This repository contains a collection of scripts for creating a fresh debian update image for Sovol SV06 ACE printers. One of the many benefits of running a custom install is that you can be sure that all software is from official sources. It will also have a smaller footprint, requiring only about half the amount of storage compared to the official image.

The scripts has been tested on a host system running the latest version of [Tuxedo OS](https://www.tuxedocomputers.com/en/TUXEDO-OS_1.tuxedo) OS, which based on the latest [Ubuntu LTS](https://ubuntu.com/download/desktop).

## Installation of Debian base
Begin by downloading the official update image to your SV06 ACE printer by running
```console 
./download-update-img.sh
``` 
You may also grab the image for your printer manually from [SV06 ACE](https://drive.google.com/drive/folders/1bf8k1qVO31uq0BIBq4jQVR3mAjd2UuXu?usp=sharing) [SV06 Plus ACE](https://drive.google.com/drive/folders/1sEsbBmP2eZxc8P9HHxHdBsMY07VvtDGa?usp=sharing).

Once the download has finished, unpack it:
```console 
./unpack-update-img.sh path-to-update-image
```
This will separate the rootfs from the kernel and the bootloader, ensuring the latter are not modified. We will now wipe the rootfs completely and debootstrap Debian onto it:
```console
WIFI_SSID=my-wifi-ssid WIFI_PASSWORD=my-wifi-password ./bootstrap-debian.sh
```
In addition to setting up a base installation, the install script will also download some additional packages and enable some system services; see the script for details - I invite you to modify it as you see fit! Once the installation has finished, repackage the image:
```console
./pack-update-img.sh
``` 
This will produce an update image ready to be flashed onto your printer. For instruction on how to flash using Windows see the [official instructions](https://wiki.sovol3d.com/en/SV06-ACE-image-flashing-tutorial), for Linux see [this](https://forum.sovol3d.com/t/linux-board-flashing-tool-for-sv06-ace/8076/4) forum post.

In summary the installation steps are as follows:
1) Download the official SV06 update image: ```./download-update-img.sh```
2) Unpack the update image: ```./unpack-update-img.sh path-to-update-image```
3) Debootstrap debian onto rootfs: ```WIFI_SSID=my-wifi-ssid WIFI_PASSWORD=my-wifi-password ./bootstrap-debian.sh```
4) Repack the image: ```./pack-update-img.sh```
5) Flash the newly created update image.

Once the image has been flashed, the printer will boot into a fresh debian install!
## Post installation set up
If networking was set up properly you should be able access the printer via SSH:
```console
ssh sovol@PRINTER_IP_ADDRESS
```
Consult your Router Admin Page for looking up the address of the printer.

In case you are unable to access it via ssh, it is also possible to access the printer by connecting a USB cable between your computer and the main board USB-C connection, and then dropping a shell into it using Android Debug Bridge:
```console
adb shell /bin/bash
```

Once SSH is working, [Klipper](https://www.klipper3d.org) can be installed by running on the host:
```console
./install-klipper.sh ip-address-of-printer
``` 
In essence, this script will clone the [Klipper](https://github.com/Klipper3d/klipper) on your printer, check out and install the branch corresponding to the Klipper version in the official Sovol update image, and lastly upload some Sovol specific Klipper files.

After installing Klipper go ahead and ssh into printer and clone [KIAUH](https://github.com/dw-0/kiauh) to install some additional software:
```console 
git clone https://github.com/dw-0/kiauh
``` 
Now run KIAUH (on printer) and follow instructions to install Moonraker and Mainsail (for the web UI):
```console
./kiauh/kiauh.sh
```
After installing Moonraker, enable the default Sovol UI for the screen:
```console
sudo systemctl enable makerbase-client
```
An alternative open source UI is [Guppy Screen](https://github.com/probielodan/guppyscreen); to install run:
```console 
./install-guppyscreen.sh
```
It is also possible to install [KlipperScreen](), see [this](https://forum.sovol3d.com/t/klipperscreen-for-sovol-sv06-ace/9112) forum post for instructions.

For camera functionality install [Crowsnest](https://github.com/mainsail-crew/crowsnest) using KIAUH. If you are interested in personalizing the boot screen see my other repo https://github.com/andrelofgren/SV06-ACE-Custom-Splash for instructions on how to do that.

In summary performing the following post-installation steps should get you a working printer:
1) Install Klipper: run ```./install-klipper.sh ip-address-of-printer``` on host
2) Clone KIAUH: run ```git clone https://github.com/dw-0/kiauh``` on printer
3) Install Moonraker and Mainsail: run ```./kiah/kiauh.sh``` on printer
4) Enable screen UI: run ```sudo systemctl enable makerbase-client``` on printer
5) Reboot printer

For general system configuration install the [Armbian configuration utility](https://docs.armbian.com/User-Guide_Armbian-Config) by following these [instructions](https://docs.armbian.com/User-Guide_Armbian-Config/#installation-on-3rd-party-linux-oA).
