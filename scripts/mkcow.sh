#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "usage: mkcow.sh /path/to/kernel/deb/file [subvolume uuid]"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "not a file: $1"
  exit 1
fi

KDEB_FILE=$1

# the predefined uuids
root_vol=e383f6f7-6572-46a9-a7fa-2e0633015231     # root vol 
ro_subvol=
rw_subvol=ebcc3123-127a-4d26-b083-38e8c0bf7f09    # rw / working subvol
tmp_subvol=07371046-38a3-43d5-9ded-d92584d7e751   # tmp / staging subvol 

if [ -z $2 ]; then
  ro_subvol=$(cat /proc/sys/kernel/random/uuid)
  echo "sub volume uuid not provided, auto generated: $ro_subvol"
elif [[ $2 =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
  ro_subvol=$2
  echo "sub volume uuid provided: $ro_subvol"
else
  echo "error: invalid sub volume uuid"
  echo "usage: mkcow.sh /path/to/kernel/deb/file [subvolume uuid]"
  exit 1
fi

# mount point & image file name
MNT=mntcow
IMG=cow.img

# create image file
rm -rf $IMG
# fallocate -l $((0xE70000 * 0x200)) $IMG
fallocate -l $((0x40000000)) $IMG

# mk root btrfs volume & mount
mkfs.btrfs -U $root_vol -f $IMG
mkdir -p $MNT
mount -o loop $IMG $MNT

# create sub-dirs
mkdir -p $MNT/boot
mkdir -p $MNT/vols

echo "generate system.env"
cat > $MNT/boot/system.env << EOF
system_l=$ro_subvol
system_l_opts=ro
system_r=$ro_subvol
system_r_opts=ro
EOF

echo "installing u-boot script"
cp scripts/u-boot/boot.cmd $MNT/boot
mkimage -C none -A arm -T script -d $MNT/boot/boot.cmd $MNT/boot/boot.scr

TMPVOL=$MNT/vols/$tmp_subvol

echo "TMPVOL: ${TMPVOL}"

btrfs subvolume create $TMPVOL
# chattr +c $TMPVOL

# expand
tar xzf cache/debase.tar.gz -C $TMPVOL

# deploy scripts
rm $TMPVOL/sbin/init
cp scripts/target/sbin/* $TMPVOL/sbin

# deploy firmware
mkdir -p $TMPVOL/lib/firmware
cp -r firmware/* $TMPVOL/lib/firmware

# add ttyGS0 to secure tty
cat >> $TMPVOL/etc/securetty << EOF

# USB Gadget Serial
ttyGS0
EOF

# set up fstab
cat > $TMPVOL/etc/fstab << EOF
# <file system>                             <mount point>     <type>  <options>                   <dump>  <fsck>
# UUID=0cbc36fa-3b85-40af-946e-f15dce29d86b   /mnt/persistent   ext4    defaults                    0       1
EOF

# set up hosts
cat > $TMPVOL/etc/hosts << EOF
127.0.0.1 localhost
127.0.1.1 winas

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# set up hostname
cat > $TMPVOL/etc/hostname << EOF
winas
EOF

# set up network interfaces
cat > $TMPVOL/etc/network/interfaces << EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
# auto eth0
# allow-hotplug eth0
# iface eth0 inet dhcp

auto lo
iface lo inet loopback
EOF

# set up timezone
cat > $TMPVOL/etc/timezone << EOF
Asia/Shanghai
EOF

# generate locale
chroot $TMPVOL locale-gen "en_US.UTF-8"

# set root password
chroot $TMPVOL bash -c "echo root:root | chpasswd"

# config network manager TODO
cat > $TMPVOL/etc/NetworkManager/NetworkManager.conf << EOF
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=no
EOF

# create system generator for mounting alt root
# mkdir $TMPVOL/etc/systemd/system-generators
# cp scripts/systemd/alt-root-mount-generator $TMPVOL/etc/systemd/system-generators

# create console for ttyGS0
chroot $TMPVOL ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service

# enable systemd-resolvd
chroot $TMPVOL systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf $TMPVOL/etc/resolv.conf

echo "installing kernel"
scripts/install-kernel.sh $TMPVOL $KDEB_FILE 

# snapshot tmp_root to ro 
# btrfs subvolume snapshot -r $TMPVOL $MNT/vols/$ro_subvol
btrfs subvolume snapshot $TMPVOL $MNT/vols/$ro_subvol
btrfs subvolume delete $TMPVOL

sync

echo "Done"
