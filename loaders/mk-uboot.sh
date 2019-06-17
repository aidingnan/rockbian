#!/bin/bash

FILE_PATH=$1
FILE_NAME=$(basename $FILE_PATH)

if [ -z $FILE_PATH ]; then
  echo "uboot file required"
  exit 1
elif [ ! -f $FILE_PATH ]; then
  echo "file not found!"
  exit 1
elif [ "$FILE_NAME" != "u-boot-dtb.bin" ] ; then
  echo "filename must be u-boot-dtb.bin"
  exit 1
fi

loaderimage --pack --uboot $FILE_PATH uboot.img 0x200000
