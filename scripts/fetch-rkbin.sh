#!/bin/bash

set -e

RAW_MASTER=https://github.com/rockchip-linux/rkbin/raw/master

mkdir -p rkbin

cd rkbin

mkdir -p RKBOOT RKTRUST bin/rk33 tools

wget $RAW_MASTER/RKBOOT/RK3328MINIALL.ini -O RKBOOT/RK3328MINIALL.ini
wget $RAW_MASTER/RKTRUST/RK3328TRUST.ini -O RKTRUST/RK3328TRUST.ini

DDRBIN=$(basename $(grep -e .*_ddr_.* RKBOOT/RK3328MINIALL.ini))
USBPLUG=$(basename $(grep -e .*_usbplug_.* RKBOOT/RK3328MINIALL.ini))
MINILOADER=$(basename $(grep -e .*_miniloader_.* RKBOOT/RK3328MINIALL.ini))
LOADER=$(basename $(grep -e .*_loader_.* RKBOOT/RK3328MINIALL.ini))
LOADER=${LOADER:5}

BL31=$(basename $(grep -e .*_bl31_.* RKTRUST/RK3328TRUST.ini))
BL32=$(basename $(grep -e .*_bl32_.* RKTRUST/RK3328TRUST.ini))

echo "DDRBIN: $DDRBIN"
echo "USBPLUG: $USBPLUG"
echo "MINILOADER: $MINILOADER"
echo "LOADER: $LOADER"
echo "BL31: $BL31"
echo "BL32: $BL32"

wget $RAW_MASTER/bin/rk33/$DDRBIN -O bin/rk33/$DDRBIN
wget $RAW_MASTER/bin/rk33/$USBPLUG -O bin/rk33/$USBPLUG
wget $RAW_MASTER/bin/rk33/$MINILOADER -O bin/rk33/$MINILOADER
wget $RAW_MASTER/bin/rk33/$BL31 -O bin/rk33/$BL31
wget $RAW_MASTER/bin/rk33/$BL32 -O bin/rk33/$BL32

wget $RAW_MASTER/tools/rkdeveloptool -O tools/rkdeveloptool
chmod a+x tools/rkdeveloptool

cd -
