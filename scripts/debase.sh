#!/bin/bash

#
# required packages: debootstrap, binfmt-support, qemu-user-static
#

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo ${SCRIPT_NAME}: "

source $SCRIPT_DIR/main.env

if [ -f $CACHE/$DEBASE_TAR ]; then
  $ECHO "$CACHE/$DEBASE_TAR exists, skip building."
  exit 0
fi

# tzdata already in base
INCS+=locales,nano,ifupdown,net-tools,zram-tools,xz-utils,parted,
INCS+=curl,wget,file,unzip,
# INCS+=python-minimal,build-essential,vim,git,wget,file,unzip,stress-ng,
INCS+=initramfs-tools,u-boot-tools,btrfs-progs,wireless-tools,i2c-tools,
INCS+=bluez,bluez-tools,bluetooth,
INCS+=openssh-server,network-manager,
# INCS+=avahi-daemon,avahi-utils,
# INCS+=samba,rsyslog
INCS+=libimage-exiftool-perl,imagemagick,ffmpeg

WORKDIR=$TMP/debase

rm -rf $WORKDIR
mkdir -p $WORKDIR
debootstrap --arch=arm64 --foreign --include=$INCS buster $WORKDIR
cp -av /usr/bin/qemu-aarch64-static $WORKDIR/usr/bin
chroot $WORKDIR /bin/bash -c "LANG=C /debootstrap/debootstrap --second-stage"

tar czf $CACHE/$DEBASE_TAR -C $WORKDIR .
$ECHO "$CACHE/$DEBASE_TAR is ready."
