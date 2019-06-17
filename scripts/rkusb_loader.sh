#!/bin/bash

mkdir -p tmp
mkdir -p loaders

cat > tmp/rk322xh.ini <<EOF
[CHIP_NAME]
NAME=RK322H
[VERSION]
MAJOR=2
MINOR=50
[CODE471_OPTION]
NUM=1
Path1=rkbin/bin/rk33/rk322xh_ddr_333MHz_v1.14.bin
Sleep=1
[CODE472_OPTION]
NUM=1
Path1=rkbin/bin/rk33/rk322xh_usbplug_v2.50.bin
[LOADER_OPTION]
NUM=2
LOADER1=FlashData
LOADER2=FlashBoot
FlashData=rkbin/bin/rk33/rk322xh_ddr_333MHz_v1.14.bin
FlashBoot=rkbin/bin/rk33/rk322xh_miniloader_v2.50.bin
[OUTPUT]
PATH=loaders/rk322xh_loader_v1.14.250.bin
EOF

rkbin/tools/boot_merger tmp/rk322xh.ini
