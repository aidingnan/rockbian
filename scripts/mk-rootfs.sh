#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo $SCRIPT_NAME:"

# dependencies
$SCRIPT_DIR/build-kernel.sh
$SCRIPT_DIR/debase.sh
$SCRIPT_DIR/fetch-node.sh
$SCRIPT_DIR/build-apps.sh

source $SCRIPT_DIR/main.env
source $CACHE/winas.env
source $CACHE/winasd.env

if [ -f $CACHE/$ROOTFS_TAR ]; then
  $ECHO "$CACHE/$ROOTFS_TAR exists, skip rebuilding"
  exit 0
fi

ROOT=$TMP/rootfs

rm -rf $ROOT
mkdir -p $ROOT 

tar xf $CACHE/$DEBASE_TAR --zstd -C $ROOT

cp scripts/target/sbin/* $ROOT/sbin

mkdir -p $ROOT/lib/firmware
cp -r firmware/* $ROOT/lib/firmware

# permit root login if ssh server installed
if [ -f $ROOT/etc/ssh/sshd_config ]; then
  sed -i '/PermitRootLogin/c\PermitRootLogin yes' $ROOT/etc/ssh/sshd_config
fi

# add ttyGS0 to secure tty
cat >> $ROOT/etc/securetty << EOF

# USB Gadget Serial
ttyGS0
EOF

# set up hosts
cat > $ROOT/etc/hosts << EOF
127.0.0.1 localhost
127.0.1.1 winas

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# set up network interfaces
cat > $ROOT/etc/network/interfaces << EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
# auto eth0
# allow-hotplug eth0
# iface eth0 inet dhcp

auto lo
iface lo inet loopback
EOF

# hostnamectl does not work in chroot
# chroot $ROOT hostnamectl set-hostname "winas"
echo "winas" > $ROOT/etc/hostname

# locale
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' $ROOT/etc/locale.gen
#  echo 'LANG="en_US.UTF-8"'> $ROOT/etc/default/locale
cat > $ROOT/etc/default/locale << EOF
LANG=en_US.UTF-8
LC_MEASUREMENT=en_US.UTF-8
LC_ADDRESS=en_US.UTF-8
LC_PAPER=en_US.UTF-8
LC_NAME=en_US.UTF-8
LC_MONETARY=en_US.UTF-8
LC_TIME=en_US.UTF-8
LC_NUMERIC=en_US.UTF-8
LC_TELEPHONE=en_US.UTF-8
LC_IDENTIFICATION=en_US.UTF-8
EOF
chroot $ROOT bash -c "$LOCALE_ENV dpkg-reconfigure --frontend=noninteractive locales"
chroot $ROOT bash -c "$LOCALE_ENV update-locale \
LANGUAGE \
LC_ALL \
LC_TIME=en_US.UTF-8 \
LC_MONETARY=en_US.UTF-8 \
LC_ADDRESS=en_US.UTF-8 \
LC_TELEPHONE=en_US.UTF-8 \
LC_NAME=en_US.UTF-8 \
LC_MEASUREMENT=en_US.UTF-8 \
LC_IDENTIFICATION=en_US.UTF-8 \
LC_NUMERIC=en_US.UTF-8 \
LC_PAPER=en_US.UTF-8 \
LANG=en_US.UTF-8"

# timezone
rm $ROOT/etc/localtime
echo "Asia/Shanghai" > $ROOT/etc/timezone
chroot $ROOT bash -c "$LOCALE_ENV dpkg-reconfigure -f noninteractive tzdata"

# set root password
chroot $ROOT bash -c "echo root:root | chpasswd"

# config network manager
cat > $ROOT/etc/NetworkManager/NetworkManager.conf << EOF
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=false

[connection]
wifi.powersave=2

[device]
wifi.scan-rand-mac-address=no
EOF

# config zram
if [ -f $ROOT/etc/default/zramswap.conf ]; then
  sed -i -e 's/#PERCENTAGE=10/PERCENTAGE=45/' $ROOT/etc/default/zramswap.conf
fi

# fix haveged conf quirk
cat > $ROOT/etc/default/haveged << EOF
DAEMON_ARGS="-d 16 -w 1024"
EOF

# TODO use cowroot-init instead, workaround
# # systemd usb-gadget target
# if [ ! -f $ROOT/lib/systemd/system/usb-gadget.target ]; then 
# cat > $ROOT/lib/systemd/system/usb-gadget.target << EOF
# #  SPDX-License-Identifier: LGPL-2.1+
# #
# #  This file is part of systemd.
# #
# #  systemd is free software; you can redistribute it and/or modify it
# #  under the terms of the GNU Lesser General Public License as published by
# #  the Free Software Foundation; either version 2.1 of the License, or
# #  (at your option) any later version.
# 
# [Unit]
# Description=Hardware activated USB gadget
# Documentation=man:systemd.special(7)
# EOF
# fi
# 
# # systemd udc rule TODO avoid existing
# sed '/^SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device",.*/a SUBSYSTEM=="udc", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}+="usb-gadget.target"' $ROOT/lib/udev/rules.d/99-systemd.rules
# 
# # usb gadget service 
# cat > $ROOT/lib/systemd/system/usb-gadget.service << EOF
# [Unit]
# Description=Config USB gadget
# Requires=sys-kernel-config.mount
# After=sys-kernel-config.mount
# 
# [Service]
# Type=simple
# ExecStart=/sbin/config-usb-gadget.sh
# RemainAfterExit=yes
# 
# [Install]
# WantedBy=usb-gadget.target
# EOF
# chroot $ROOT systemctl enable usb-gadget.service

# overriding serial-getty@ttyGS0
mkdir -p $ROOT/etc/systemd/system/serial-getty@ttyGS0.service.d/
cat > $ROOT/etc/systemd/system/serial-getty@ttyGS0.service.d/override.conf << EOF
ConditionPathExists=/run/cowroot/root/boot/.root
EOF
chroot $ROOT systemctl enable serial-getty@ttyGS0.service

# enable systemd-resolvd
chroot $ROOT systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf $ROOT/etc/resolv.conf

# install node
tar xf cache/node-v10.16.0-linux-arm64.tar.xz -C $ROOT/usr --strip-components=1

# install winas
mkdir -p $ROOT/root/winas
tar xf $CACHE/$WINAS_TAR -C $ROOT/root/winas

# install winasd and create systemd unit
mkdir -p $ROOT/root/winasd
tar xf $CACHE/$WINASD_TAR -C $ROOT/root/winasd

cat > $ROOT/lib/systemd/system/winasd.service << EOF
[Unit]
Description=Winas Daemon Service
Requires=network.target
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node ./src/app.js
WorkingDirectory=/root/winasd
Restart=always
Environment=NODE_ENV=testBackus

LimitNOFILE=infinity
LimitCORE=infinity
StandardInput=null
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=winasd
PIDFile=/run/winasd.pid
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

ln -s /lib/systemd/system/winasd.service $ROOT/etc/systemd/system/multi-user.target.wants/winasd.service

$ECHO "installing kernel"
scripts/install-kernel.sh $ROOT $CACHE/$KERNEL_DEB

tar cf $TMP/$ROOTFS_TAR --zstd -C $ROOT .
mv $TMP/$ROOTFS_TAR $CACHE/$ROOTFS_TAR

$ECHO "$ROOTFS_TAR is ready"
