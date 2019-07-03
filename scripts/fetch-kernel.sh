#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")

source $SCRIPT_DIR/main.env

# TODO
MAIN_VER=${KERNEL_VER:0:1}
KERNEL_URL=https://cdn.kernel.org/pub/linux/kernel/v${MAIN_VER}.x/$KERNEL_TAR

if [ -f $CACHE/$KERNEL_TAR ]; then exit; fi

KTMP=$TMP/tmp_kernel

wget -O $KTMP $KERNEL_URL
mv $KTMP $CACHE/$KERNEL_TAR
