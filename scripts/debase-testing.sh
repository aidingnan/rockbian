#!/bin/bash

#
# required packages: debootstrap, binfmt-support, qemu-user-static
#

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(dirname "$0")
ECHO="echo ${SCRIPT_NAME}: "

source $SCRIPT_DIR/main.env

if [ -f $CACHE/$DEBASE_TESTING_TAR ]; then
  $ECHO "$CACHE/$DEBASE_TESTING_TAR exists, skip building"
  exit 0
fi

$ECHO "building $DEBASE_TESTING_TAR ..."

DIR=$TMP/debase-testing

INCS+=locales,nano,ifupdown,net-tools,zram-tools,xz-utils,parted,
INCS+=curl,wget,file,unzip,vim,wget,file,unzip,stress-ng,
INCS+=initramfs-tools,u-boot-tools,btrfs-progs,wireless-tools,i2c-tools,
INCS+=bluez,bluez-tools,bluetooth,
INCS+=openssh-server,network-manager,

rm -rf $DIR
mkdir -p $DIR
debootstrap --arch=arm64 --foreign --variant=minbase buster $DIR
cp -av /usr/bin/qemu-aarch64-static $DIR/usr/bin
chroot $DIR /bin/bash -c "LANG=C /debootstrap/debootstrap --second-stage"
tar czf $CACHE/$DEBASE_TESTING_TAR -C $DIR .

$ECHO "$DEBASE_TESTING_TAR is ready"
