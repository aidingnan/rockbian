#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")

source $SCRIPT_DIR/main.env

KBUILD=$TMP/kbuild

if [ -f $CACHE/$KERNEL_DEB ]; then
  echo "kernel deb file found in cahce, skip building"
  exit
else
  echo "kernel deb file not found in cache, building..."
fi

echo "removing old workspace"
rm -rf $KBUILD
mkdir -p $KBUILD
echo "extracting tar ball into workspace"
tar xf $CACHE/$KERNEL_TAR -C $KBUILD

KSRC=$KBUILD/linux-${KERNEL_VER}

echo "PWD: $(pwd)"

# copy config fragments
cp kernel/configs/* $KSRC/arch/arm64/configs
# copy dts files
cp kernel/dts/* $KSRC/arch/arm64/boot/dts/rockchip/
# add backus
DTB_MAKEFILE=$KSRC/arch/arm64/boot/dts/rockchip/Makefile
sed -i '/.*rk3328-evb.*/a dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3328-backus.dtb' $DTB_MAKEFILE

make -C $KSRC ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig patch.config
make -C $KSRC ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j8 bindeb-pkg
cp $KBUILD/$KERNEL_DEB $CACHE
