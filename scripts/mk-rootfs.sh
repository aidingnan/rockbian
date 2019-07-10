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

tar xf $CACHE/$DEBASE_TAR -C $ROOT

# TODO
rm $ROOT/sbin/init
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

# config network manager
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

# create console for ttyGS0 TODO serial-getty
chroot $ROOT ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service

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
[unit]
Description=Winas Daemon Service
Requires=network.target
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node ./src/app.js
WorkingDirectory=/root/winasd
Restart=always

LimitNOFILE=infinity
LimitCORE=inifinity
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

# system-nspawn does not work properly
ln -s /lib/systemd/system/winasd.service $ROOT/etc/systemd/system/multi-user.target.wants/winasd.service

$ECHO "installing kernel"
scripts/install-kernel.sh $ROOT $CACHE/$KERNEL_DEB

tar cJf $TMP/$ROOTFS_TAR -C $ROOT .
mv $TMP/$ROOTFS_TAR $CACHE/$ROOTFS_TAR

$ECHO "$ROOTFS_TAR is ready"
