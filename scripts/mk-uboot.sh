#!/bin/bash

# output: 
#   rkbin/uboot.img
#   rkbin/uboot-{branch}-{sha}.img

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo $SCRIPT_NAME:"

# dependencies
$SCRIPT_DIR/fetch-uboot.sh

source $SCRIPT_DIR/main.env
source $UBOOT_ENV

if [ -f rkbin/$UBOOT_IMG ]; then
  $ECHO "$UBOOT_IMG is update-to-date, skip building"
  exit 0
fi 

TMPDIR=tmp/u-boot-$UBOOT_SHA

rm -rf $TMPDIR
unzip $CACHE/$UBOOT_ZIP -d tmp

make -C $TMPDIR ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- rk3328_backus_defconfig
make -C $TMPDIR ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j8

rkbin/tools/loaderimage --pack --uboot $TMPDIR/u-boot-dtb.bin rkbin/$UBOOT_IMG 0x200000

# rkdeveloptool reject symbolic link
ln rkbin/$UBOOT_IMG rkbin/uboot.img
