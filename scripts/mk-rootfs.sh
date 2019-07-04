#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")

# dependencies
$SCRIPT_DIR/debase.sh
$SCRIPT_DIR/fetch-node.sh
$SCRIPT_DIR/build-kernel.sh
$SCRIPT_DIR/build-apps.sh

source $SCRIPT_DIR/main.env
source $CACHE/winas.env
source $CACHE/winasd.env

if [ -f $CACHE/$ROOTFS_TAR ]; then
  echo "$CACHE/$ROOTFS_TAR exists, skip rebuilding."
  exit 0
fi

ROOT=$TMP/rootfs

rm -rf $ROOT
mkdir -p $ROOT 

tar xzf $CACHE/$DEBASE_TAR -C $ROOT

cp scripts/target/sbin/* $ROOT/sbin

mkdir -p $ROOT/lib/firmware
cp -r firmware/* $ROOT/lib/firmware

# permit root login
sed -i '/PermitRootLogin/c\PermitRootLogin yes' $ROOT/etc/ssh/sshd_config

# add ttyGS0 to secure tty
cat >> $ROOT/etc/securetty << EOF

# USB Gadget Serial
ttyGS0
EOF

# set up fstab
# cat > $ROOT/etc/fstab << EOF
# <file system>                             <mount point>     <type>  <options>                   <dump>  <fsck>
# UUID=0cbc36fa-3b85-40af-946e-f15dce29d86b   /mnt/persistent   ext4    defaults                    0       1
# EOF

# set up hosts
cat > $ROOT/etc/hosts << EOF
127.0.0.1 localhost
127.0.1.1 winas

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# set up hostname
cat > $ROOT/etc/hostname << EOF
winas
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

# set up timezone
cat > $ROOT/etc/timezone << EOF
Asia/Shanghai
EOF

# generate locale
chroot $ROOT locale-gen "en_US.UTF-8"

# set root password
chroot $ROOT bash -c "echo root:root | chpasswd"

# config network manager TODO
cat > $ROOT/etc/NetworkManager/NetworkManager.conf << EOF
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=no
EOF

# create system generator for mounting alt root
# mkdir $ROOT/etc/systemd/system-generators
# cp scripts/systemd/alt-root-mount-generator $ROOT/etc/systemd/system-generators

# create console for ttyGS0
chroot $ROOT ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service

# enable systemd-resolvd
chroot $ROOT systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf $ROOT/etc/resolv.conf

# install node
tar xf cache/node-v10.16.0-linux-arm64.tar.xz -C $ROOT/usr --strip-components=1

echo "installing kernel"
scripts/install-kernel.sh $ROOT $KDEB_FILE 

tar czf $TMP/$ROOTFS_TAR -C $ROOT .
mv $TMP/$ROOTFS_TAR $CACHE/$ROOTFS_TAR

echo "Done"



