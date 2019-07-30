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
$SCRIPT_DIR/mk-rootfs.sh

source $SCRIPT_DIR/main.env

# predefined uuids
root_vol=e383f6f7-6572-46a9-a7fa-2e0633015231           # root vol 
working_subvol=ebcc3123-127a-4d26-b083-38e8c0bf7f09     # rw / working subvol, not used in script
staging_subvol=07371046-38a3-43d5-9ded-d92584d7e751     # tmp / staging subvol 
initial_subvol=$(cat /proc/sys/kernel/random/uuid)      # initial subvol

# mount point & image file name
MNT=mntvol
IMG=$TMP/vol.img

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
mkdir -p $MNT/refs/tags

# set engineering mode
mkdir -p $MNT/data/root.0
touch $MNT/data/root.0/engineering
ln -s root.0 $MNT/data/root

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
for i in bin etc lib root sbin usr var
do
  mkdir $TMPVOL/$i
  chattr +c $TMPVOL/$i
done
tar xf $CACHE/$ROOTFS_TAR --zstd -C $TMPVOL
btrfs subvolume snapshot -r $TMPVOL $MNT/vols/$initial_subvol
btrfs subvolume delete $TMPVOL

echo "save subvol tags"
echo "$initial_subvol" > $MNT/refs/tags/initial
echo "$working_subvol" > $MNT/refs/tags/working
echo "$staging_subvol" > $MNT/refs/tags/staging

$ECHO "saving commit and tag if any"
COMMIT="$(git rev-parse HEAD)"
echo "$COMMIT" > $MNT/boot/.commit

{
  TAG="$(git describe --exact-match --tag $COMMIT)"
} || {
  TAG=
}
if [ "$TAG" ]; then
  echo "$TAG" > $MNT/boot/.tag
fi

sync
umount $MNT

zstd $IMG
mv $IMG cache
mv $IMG.zst cache

echo "vol.img and vol.img.zst are ready"
