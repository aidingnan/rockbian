#!/bin/bash

set -e

RAW_MASTER=https://github.com/rockchip-linux/rkbin/raw/master
RKBIN=rkbin

rm -rf tmp/rkbin
mkdir -p tmp/rkbin

cd tmp/rkbin

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

wget $RAW_MASTER/tools/boot_merger -O tools/boot_merger
wget $RAW_MASTER/tools/loaderimage -O tools/loaderimage
wget $RAW_MASTER/tools/trust_merger -O tools/trust_merger
wget $RAW_MASTER/tools/rkdeveloptool -O tools/rkdeveloptool
wget $RAW_MASTER/tools/upgrade_tool -O tools/upgrade_tool

chmod a+x tools/boot_merger
chmod a+x tools/loaderimage
chmod a+x tools/trust_merger
chmod a+x tools/rkdeveloptool
chmod a+x tools/upgrade_tool

# rkusb loader
tools/boot_merger RKBOOT/RK3328MINIALL.ini
ln -s $LOADER rk3328_loader 

# idbloader.img
mkimage -n rk3328 -T rksd -d bin/rk33/$DDRBIN idbloader.img
cat bin/rk33/$MINILOADER >> idbloader.img

# trust.img
tools/trust_merger RKTRUST/RK3328TRUST.ini

cd -

rm -rf rkbin
mv tmp/rkbin rkbin
