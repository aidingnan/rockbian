#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo $SCRIPT_NAME:"

# dependencies
$SCRIPT_DIR/fetch-rkbin.sh
$SCRIPT_DIR/mk-uboot.sh

source $SCRIPT_DIR/main.env
source $UBOOT_ENV

mkdir -p rkbin
cd rkbin

# rkusb loader
tools/boot_merger RKBOOT/RK3328MINIALL.ini

# idbloader.img
DDRBIN=$(basename $(grep -e .*_ddr_.* RKBOOT/RK3328MINIALL.ini))
MINILOADER=$(basename $(grep -e .*_miniloader_.* RKBOOT/RK3328MINIALL.ini))
tools/mkimage -n rk3328 -T rksd -d bin/rk33/$DDRBIN idbloader.img
cat bin/rk33/$MINILOADER >> idbloader.img

# uboot.img
tools/loaderimage --pack --uboot $UBOOT_BIN $UBOOT_IMG 0x200000

# trust.img
tools/trust_merger RKTRUST/RK3328TRUST.ini

IMG=header.img

# 0xE90000 * 0x200 (512) -> 7818182656
fallocate -l 7818182656 $IMG

# 0x10000 -> 65536
# 0xE90000 - 1 -> 15269887
fdisk $IMG << EOF
o
n
p
1
65536
15269887
w
EOF

truncate -s $((0x10000 * 0x200)) $IMG

# 0x40
dd if=idbloader.img of=$IMG bs=512 seek=64 conv=notrunc
# 0x4000
dd if=$UBOOT_IMG of=$IMG bs=512 seek=16384 conv=notrunc
# 0x6000
dd if=trust.img of=$IMG bs=512 seek=24576 conv=notrunc
