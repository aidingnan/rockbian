#!/bin/bash

#
# required packages: debootstrap, binfmt-support, qemu-user-static
#

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(dirname "$0")
ECHO="echo ${SCRIPT_NAME}: "

source $SCRIPT_DIR/main.env

$SCRIPT_DIR/check-qemu.sh

if [ -f $CACHE/$DEBASE_TESTING_TAR ]; then
  $ECHO "$CACHE/$DEBASE_TESTING_TAR exists, skip building"
  exit 0
fi

$ECHO "building $DEBASE_TESTING_TAR ..."

DIR=$TMP/debase-testing

INCS+=locales,tzdata,initramfs-tools,u-boot-tools,ca-certificates,
INCS+=btrfs-progs,i2c-tools,zram-tools,xz-utils,parted,openssl,
INCS+=nano,curl,wget,file,unzip,
INCS+=net-tools,wireless-tools,network-manager,
INCS+=bluez,bluez-tools,bluetooth,
INCS+=openssh-server,
# INCS+=libimage-exiftool-perl,imagemagick,ffmpeg
INCS+=iperf3,stress-ng

rm -rf $DIR
mkdir -p $DIR
debootstrap --arch=arm64 --foreign --variant=minbase --include=$INCS  buster $DIR
cp -av /usr/bin/qemu-aarch64-static $DIR/usr/bin
chroot $DIR /bin/bash -c "LANG=C /debootstrap/debootstrap --second-stage"
tar cJf $CACHE/$DEBASE_TESTING_TAR -C $DIR .

$ECHO "$DEBASE_TESTING_TAR is ready"
