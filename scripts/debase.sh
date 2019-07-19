#!/bin/bash

#
# required packages: debootstrap, binfmt-support, qemu-user-static
#

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo ${SCRIPT_NAME}:"

source $SCRIPT_DIR/main.env

$SCRIPT_DIR/check-qemu.sh

if [ -f $CACHE/$DEBASE_TAR ]; then
  $ECHO "$CACHE/$DEBASE_TAR exists, skip building"
  exit 0
fi

$ECHO "building $DEBASE_TAR ..."

DIR=$TMP/debase

INCS+=locales,tzdata,initramfs-tools,u-boot-tools,ca-certificates,haveged,zstd,isc-dhcp-client,isc-dhcp-server,ifupdown,
INCS+=btrfs-progs,i2c-tools,zram-tools,xz-utils,parted,openssl,rfkill,
INCS+=nano,curl,wget,file,unzip,iputils-ping,
INCS+=net-tools,wireless-tools,network-manager,
INCS+=bluez,bluez-tools,bluetooth,
INCS+=openssh-server,
INCS+=libimage-exiftool-perl,imagemagick,ffmpeg,
INCS+=iperf3,stress-ng

LOG=$TMP/debase.log

rm -rf $DIR
mkdir -p $DIR
bash -c "$LOCALE_ENV \
  debootstrap --arch=arm64 --foreign --variant=minbase --include=$INCS buster $DIR"
cp -av /usr/bin/qemu-aarch64-static $DIR/usr/bin
chroot $DIR /bin/bash -c "$LOCALE_ENV /debootstrap/debootstrap --second-stage"
tar cf $CACHE/$DEBASE_TAR --zstd -C $DIR .

$ECHO "$DEBASE_TAR is ready"
