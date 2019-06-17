#!/bin/bash

# debootstrap, binfmt-support, qemu-user-static

# tzdata already in base
INCS+=locales,nano,vim,ifupdown,net-tools,
INCS+=initramfs-tools,u-boot-tools,btrfs-progs,wireless-tools,i2c-tools,
INCS+=bluez,bluez-tools,bluetooth,
INCS+=openssh-server,network-manager,
INCS+=avahi-daemon,avahi-utils,
# INCS+=samba,rsyslog
INCS+=libimage-exiftool-perl,imagemagick,ffmpeg

rm -rf debase
mkdir debase
debootstrap --arch=arm64 --foreign --include=$INCS buster debase
cp -av /usr/bin/qemu-aarch64-static debase/usr/bin
chroot debase /bin/bash -c "LANG=C /debootstrap/debootstrap --second-stage"

mkdir -p cache
tar czf cache/debase.tar.gz -C debase .
