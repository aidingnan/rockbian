#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo $SCRIPT_NAME:"

# dependencies
$SCRIPT_DIR/mk-rootfs.sh
# $SCRIPT_DIR/mk-rootfs-testing.sh

source $SCRIPT_DIR/main.env

# predefined uuids
root_vol=e383f6f7-6572-46a9-a7fa-2e0633015231           # root vol 
working_subvol=ebcc3123-127a-4d26-b083-38e8c0bf7f09     # rw / working subvol, not used in script
staging_subvol=07371046-38a3-43d5-9ded-d92584d7e751     # tmp / staging subvol 
initial_subvol=$(cat /proc/sys/kernel/random/uuid)      # initial subvol
# testing_subvol=$(cat /proc/sys/kernel/random/uuid)      # testing subvol

# mount point & image file name
MNT=mntvol
IMG=vol.img

# create image file
rm -rf $IMG
# fallocate -l $((0xE70000 * 0x200)) $IMG
fallocate -l $((0xC0000000)) $IMG

# mk root btrfs volume & mount
mkfs.btrfs -U $root_vol -f $IMG
mkdir -p $MNT
mount -o loop $IMG $MNT

# create sub-dirs
mkdir -p $MNT/boot
mkdir -p $MNT/vols
mkdir -p $MNT/refs/tags
mkdir -p $MNT/data

# boot from testing in rooted mode
touch $MNT/boot/.root

echo "generating system.env, boot from testing subvol"
cat > $MNT/boot/system.env << EOF
system_l=$initial_subvol
system_l_opts=ro
system_r=$initial_subvol
system_r_opts=ro
EOF

echo "installing u-boot script"
cp scripts/u-boot/boot.cmd $MNT/boot
mkimage -C none -A arm -T script -d $MNT/boot/boot.cmd $MNT/boot/boot.scr

TMPVOL=$MNT/vols/$staging_subvol

echo "creating initial subvol"
btrfs subvolume create $TMPVOL
tar xf $CACHE/$ROOTFS_TAR -C $TMPVOL
btrfs subvolume snapshot -r $TMPVOL $MNT/vols/$initial_subvol
btrfs subvolume delete $TMPVOL

# echo "creating testing subvol"
# btrfs subvolume create $TMPVOL
# tar xf $CACHE/$ROOTFS_TESTING_TAR -C $TMPVOL
# btrfs subvolume snapshot -r $TMPVOL $MNT/vols/$testing_subvol
# btrfs subvolume delete $TMPVOL

echo "save subvol tags"
echo "$initial_subvol" > $MNT/refs/tags/initial
# echo "$testing_subvol" > $MNT/refs/tags/testing
echo "$working_subvol" > $MNT/refs/tags/working
echo "$staging_subvol" > $MNT/refs/tags/staging

sync

xz -k $IMG
mv $IMG.xz cache

echo "vol.img is ready"
