Building Custom Kernel
========================


* Go to https://github.com/altera-opensource/linux-socfpga

* Git clone the repo

* Switch to an altera's branch like "git checkout  remotes/origin/socfpga-5.1"

* Gunzip /proc/config.gz from DE1 board to .config

* Do oldconfig, like "make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- oldconfig", lot of conf updates (4.5 vs 5.1)

* Do menuconfig to add/config stuff

* Build deb package with "make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j 8 KBUILD_DEBARCH=armhf deb-pkg"

* Copy/scp deb files to DE1 board

* install with

    sudo dpkg -i \*.deb

* Mount /dev/mmcblk0p1 on /boot and cd to it

* Copy zImage to zImage.old (in case of problems)

* Copy vmlinuz-5.1.0-00097-ga64da520ac0b to zImage

* Sync

* Reboot
