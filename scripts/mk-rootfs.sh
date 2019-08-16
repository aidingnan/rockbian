#!/bin/bash

set -e

if [ "$(git diff-index HEAD --)" ]; then
  echo "git repo not clean"
  git diff-index HEAD --
  exit 1
fi

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo $SCRIPT_NAME:"

# dependencies
$SCRIPT_DIR/build-kernel.sh
$SCRIPT_DIR/debase.sh
$SCRIPT_DIR/fetch-atecc.sh
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

cp $CACHE/$ATECC_BIN $ROOT/sbin
chmod a+x $ROOT/sbin/$ATECC_BIN
cp scripts/target/sbin/* $ROOT/sbin

# useless
mkdir -p $ROOT/lib/firmware
cp -r firmware/* $ROOT/lib/firmware

# mkdir -p $ROOT/root/.ssh
# chmod 700 $ROOT/root/.ssh
# cat keys/id_rsa.pub >> $ROOT/root/.ssh/authorized_keys
# chmod 600 $ROOT/root/.ssh/authorized_keys

# add ttyGS0 to secure tty
cat >> $ROOT/etc/securetty << EOF

# USB Gadget Serial
ttyGS0
EOF

# # set up hosts
# cat > $ROOT/etc/hosts << EOF
# 127.0.0.1 localhost
# 127.0.1.1 winas
#
# # The following lines are desirable for IPv6 capable hosts
# ::1     localhost ip6-localhost ip6-loopback
# ff02::1 ip6-allnodes
# ff02::2 ip6-allrouters
# EOF

# set up network interfaces
cat > $ROOT/etc/network/interfaces << EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:

auto lo
iface lo inet loopback
EOF

# symlink hosts
rm -rf $ROOT/etc/hosts
ln -s "/run/cowroot/root/data/init/hosts" $ROOT/etc/hosts

# symlink hostname
rm -rf $ROOT/etc/hostname
ln -s "/run/cowroot/root/data/init/hostname" $ROOT/etc/hostname

# symlink machine-id
rm -rf $ROOT/etc/machine-id
ln -s "/run/cowroot/root/data/init/machine-id" $ROOT/etc/machine-id

# locale
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' $ROOT/etc/locale.gen
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

# let nm manage usb net
sed -i 's/^ENV{DEVTYPE}=="gadget"/# ENV{DEVTYPE}=="gadget"/' $ROOT/lib/udev/rules.d/85-nm-unmanaged.rules

# symlink connections dir
rm -rf $ROOT/etc/NetworkManager/system-connections/
mkdir -p $ROOT/etc/NetworkManager/
ln -s /run/cowroot/root/data/nm-connections $ROOT/etc/NetworkManager/system-connections

# config usb net
cat > $ROOT/lib/systemd/system/preconfig-network-manager.service << EOF
[Unit]
Description=Preconfig NetworkManager
# Wants=network.target
Before=NetworkManager.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/preconfig-network-manager.sh

[Install]
WantedBy=multi-user.target
EOF
chroot $ROOT systemctl enable preconfig-network-manager.service

# config zram
if [ -f $ROOT/etc/default/zramswap.conf ]; then
  sed -i -e 's/#PERCENTAGE=10/PERCENTAGE=45/' $ROOT/etc/default/zramswap.conf
fi

# fix haveged conf quirk
cat > $ROOT/etc/default/haveged << EOF
DAEMON_ARGS="-d 16 -w 1024"
EOF

cat > $ROOT/lib/systemd/system/config-usb-gadget.service << EOF
[Unit]
Description=Config USB Gadget
ConditionPathIsDirectory=/sys/kernel/config/usb_gadget
After=sys-kernel-config.mount

[Service]
Type=simple
Restart=no
ExecStart=/sbin/config-usb-composite.sh

[Install]
WantedBy=multi-user.target
EOF
chroot $ROOT systemctl enable config-usb-gadget.service

# overriding serial-getty@ttyGS0
mkdir -p $ROOT/etc/systemd/system/serial-getty@ttyGS0.service.d/
cat > $ROOT/etc/systemd/system/serial-getty@ttyGS0.service.d/override.conf << EOF
ConditionPathExists=/run/cowroot/root/data/root
EOF
chroot $ROOT systemctl enable serial-getty@ttyGS0.service

cat > $ROOT/lib/systemd/system/cowroot-auto-commit.service << EOF
[Unit]
Description=Cowroot Auto Commit

[Service]
Type=oneshot
ExecStop=/sbin/cowroot-commit

[Install]
WantedBy=multi-user.target
EOF
chroot $ROOT systemctl enable cowroot-auto-commit.service

# permit root login if ssh server installed
if [ -f $ROOT/etc/ssh/sshd_config ]; then
  sed -i '/PermitRootLogin/c\PermitRootLogin yes' $ROOT/etc/ssh/sshd_config
  sed -i '/ConditionPathExists=.*/c\ConditionPathExists=/run/cowroot/root/data/root' $ROOT/lib/systemd/system/ssh.service
fi

cat >> $ROOT/lib/systemd/system/preconfig-ssh.service << EOF
[Unit]
Description=Preconfigure SSH
Before=ssh.service

[Service]
Type=oneshot
ExecStart=/sbin/preconfig-ssh.sh

[Install]
WantedBy=multi-user.target
EOF
chroot $ROOT systemctl enable preconfig-ssh.service

cat >> $ROOT/lib/systemd/system/preconfig-bluetooth.service << EOF
[Unit]
Description=Preconfigure Bluetooth
Before=bluetooth.service
After=sys-kernel-debug.mount

[Service]
Type=oneshot
ExecStart=/sbin/preconfig-bluetooth.sh

[Install]
WantedBy=bluetooth.target
EOF
chroot $ROOT systemctl enable preconfig-bluetooth.service

# disable apt services
chroot $ROOT systemctl mask apt-daily-upgrade.timer
chroot $ROOT systemctl mask apt-daily.timer

# enable systemd-resolvd
chroot $ROOT systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf $ROOT/etc/resolv.conf

# install node
tar xf $CACHE/$NODE_TAR -C $ROOT/usr --strip-components=1

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
ConditionPathExists=!/run/cowroot/root/data/root/engineering

[Service]
Type=simple
ExecStart=/usr/bin/node ./src/app.js
WorkingDirectory=/root/winasd
Restart=always

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

$ECHO "remove initrd"
mv $ROOT/boot/uInitrd $ROOT/boot/uInitrd-unused

COMMIT="$(git rev-parse HEAD)"
$ECHO "saving commit $COMMIT to /boot/.commit"
echo "$COMMIT" > $ROOT/boot/.commit

{
  TAG="$(git describe --exact-match --tag $COMMIT)"
} || {
  TAG=
}
if [ "$TAG" ]; then
  $ECHO "saving tag $TAG to both /boot/.tag and /etc/version"
  echo "$TAG" > $ROOT/boot/.tag
  echo "$TAG" > $ROOT/etc/version
fi

tar cf $TMP/$ROOTFS_TAR --zstd -C $ROOT .
mv $TMP/$ROOTFS_TAR $CACHE/$ROOTFS_TAR

$ECHO "$ROOTFS_TAR is ready"
