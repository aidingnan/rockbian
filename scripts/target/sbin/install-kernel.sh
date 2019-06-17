#!/bin/bash

set -e

FILE_PATH=$1
FILE_NAME=$(basename $FILE_PATH)

if [ -z $FILE_PATH ]; then
  echo "kernel (deb) filename required"
  exit 1
elif [ ! -f $FILE_PATH ]; then
  echo "file not found"
  exit 1
elif expr match $FILE_NAME '^linux-image-[0-9]\+\.[0-9]\+\.[0-9]\+' > /dev/null; then
  VER=$(expr match $FILE_NAME '^linux-image-[0-9]\+\.[0-9]\+\.[0-9]\+')
  VER=$(expr substr $FILE_NAME 1 $VER)
  VER=$(expr substr $VER 13 100)
  echo "version: $VER" 
else
  echo "invalid filename pattern, must start w/ linux-image-xx.xx.xx"
  exit
fi

# install kernel package
dpkg -i $FILE_PATH

# update Image
rm -rf /boot/Image
mv /boot/vmlinuz-${VER} /boot/Image.gz
gunzip /boot/Image.gz

# update uInitrd
rm -rf /boot/uInitrd
mkimage -A arm64 -O linux -T ramdisk -C gzip -n uInitrd -d /boot/initrd.img-${VER} /boot/uInitrd
rm -rf /boot/initrd.img-${VER}

# update dtbs
rm -rf /boot/dtbs
ln -s /usr/lib/linux-image-${VER} /boot/dtbs

