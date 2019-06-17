#!/bin/bash

usage() {
  echo "usage: install-kernel.sh /path/to/root/dir /path/to/kernel-deb-file"
}

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

ROOT_DIR=$1
FILE_PATH=$2
FILE_NAME=$(basename $FILE_PATH)

if [ ! -d $ROOT_DIR ]; then
  echo "bad root dir: $ROOT_DIR"
  usage
  exit 1
fi

if [ ! -f $FILE_PATH ]; then
  echo "not a file: $FILE_PATH"
  usage
  exit 1
elif expr match $FILE_NAME '^linux-image-[0-9]\+\.[0-9]\+\.[0-9]\+' > /dev/null; then
  VER=$(expr match $FILE_NAME '^linux-image-[0-9]\+\.[0-9]\+\.[0-9]\+')
  VER=$(expr substr $FILE_NAME 1 $VER)
  VER=$(expr substr $VER 13 100)
  echo "version: $VER" 
else
  echo "invalid filename pattern, must start w/ linux-image-xx.xx.xx"
  exit 1
fi

cp $FILE_PATH $ROOT_DIR
chroot $ROOT_DIR install-kernel.sh $FILE_NAME
rm -rf $ROOT_DIR/$FILE_NAME

sync



