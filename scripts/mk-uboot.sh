#!/bin/bash

set -e

BUILD=tmp/u-boot

rm -rf $BUILD
git clone https://github.com/aidingnan/u-boot.git $BUILD

cd $BUILD
git checkout dingnan-backus
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- rk3328_backus_defconfig
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j8
cd -

rkbin/tools/loaderimage --pack --uboot $BUILD/u-boot-dtb.bin rkbin/uboot.img 0x200000
