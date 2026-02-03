# SV06-ACE-debian-install
## About
This repository contains a collection of scripts for creating a fresh debian update image for Sovol SV06 ACE printers. The main benefit of running a custom install is that you can be sure that all software is coming from official sources. It will also have a smaller footprint, requiring only about half the amount of storage compared to the official image.

## Installing
Begin by downloading the update image to your SV06 ACE printer by running
```console 
./download-update-img.sh
``` 
You may also grab the image for your printer manually from https://drive.google.com/drive/folders/1bf8k1qVO31uq0BIBq4jQVR3mAjd2UuXu?usp=sharing or from https://drive.google.com/drive/folders/1sEsbBmP2eZxc8P9HHxHdBsMY07VvtDGa?usp=sharing for SV06 Ace and SV06 Plus ACE, respectively. Next unpack the image:
```console 
./unpack-update-img.sh path-to-update-image
```
This will separate the rootfs (rootfs.img) from the other image such as the kernel (boot.img) and the bootloader (uboot.img). Once the script has finished unpacking we are now ready to bootstrap Debian onto the rootfs:
```console
WIFI_SSID=my-wifi-ssid WIFI_PASSWORD=my-wifi-password ./bootstrap-debian.sh
```
In addition to setting up a base installation, the install script will also download some additional packages and perform some configuration of wifi. When the installation has finished you are now ready to pack the image
```console
./pack-update-img.sh
``` 
This will produce an update image ready to be flashed on your printer. Instructions for flashing the image on Windows and Linux can be found on https://wiki.sovol3d.com/en/SV06-ACE-image-flashing-tutorial and https://forum.sovol3d.com/t/linux-board-flashing-tool-for-sv06-ace/8076, respectively.

In summary the step are:
1) Download the official SV06 update image: ```./download-update-img.sh```
2) Unpack the update image: ```./unpack-update-img.sh path-to-update-image```
3) Debootstrap debian onto rootfs,img: ```WIFI_SSID=my-wifi-ssid WIFI_PASSWORD=my-wifi-password ./bootstrap-debian.sh```
4) Repack the image: ```./pack-update-img.sh```
5) Flash the newly created update image

Once the image has flashed the printer will boot into a fresh debian install! If networking was set up correctly you should be able access the printer via SSH. In case wifi failed, one may also access the printer via the main board USB-C connection by dropping a terminal into it using the Android Debugging Bridge.
## Post installation set up
Once you have flashed the fresh update image and booted up the printer you install klipper on the printer by running
```console
./install-klipper.sh ip-address-of-printer
``` 
Before running this script, however, you need to determine the IP of you printer, which you can find from your Router Admin Page (e.g., 192.168.1.1, 192.168.0.1). In essence, the Klipper install script will clone https://github.com/Klipper3d/klipper on your printer, check out and install the branch corresponding to the Klipper version in the official Sovol update image, and lastly upload some Sovol specific Klipper files. After installing Klipper you may go ahead and clone KIAUH on the printer:

```console 
git clone https://github.com/dw-0/kiauh
``` 
Now run KIAUH on printer to install Moonraker and Mainsail (for the web UI):
```console
./kiauh/kiauh.sh
```
After installing Moonraker, enable the default Sovol UI:
```console
sudo systemctl enable makerbase-client
```
An alternative Screen UI is Guppy Screen, available from https://github.com/probielodan/guppyscreen. To install upload and run ```./install-guppyscreen.sh``` on the printer. For camera to function tou will need to install Crowsnest which can be installed using KIAUH. For personalizing the boot screen see my other repo https://github.com/andrelofgren/SV06-ACE-Custom-Splash.

In summary to get a working printer do the following
1) Install Klipper: run  ```./install-klipper.sh ip-address-of-printer``` on host
2) Clone KIAUH: run  ```git clone https://github.com/dw-0/kiauh``` on printer
3) Install Moonraker and Mainsail: run ```./kiah/kiauh.sh``` on printer
