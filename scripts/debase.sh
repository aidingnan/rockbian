#!/bin/bash

# debootstrap, binfmt-support, qemu-user-static

CACHE=cache
DEBASE=tmp/debase

# tzdata already in base
INCS+=locales,nano,ifupdown,net-tools,zram-tools,xz-utils,
INCS+=python-minimal,build-essential,vim,git,wget,file,unzip,stress-ng,
INCS+=initramfs-tools,u-boot-tools,btrfs-progs,wireless-tools,i2c-tools,
INCS+=bluez,bluez-tools,bluetooth,
INCS+=openssh-server,network-manager,
# INCS+=avahi-daemon,avahi-utils,
# INCS+=samba,rsyslog
INCS+=libimage-exiftool-perl,imagemagick,ffmpeg

rm -rf $DEBASE
mkdir -p $DEBASE
debootstrap --arch=arm64 --foreign --include=$INCS buster $DEBASE
cp -av /usr/bin/qemu-aarch64-static $DEBASE/usr/bin
chroot $DEBASE /bin/bash -c "LANG=C /debootstrap/debootstrap --second-stage"

mkdir -p cache
tar czf $CACHE/debase.tar.gz -C $DEBASE .
