#!/bin/bash

#
# required packages: debootstrap, binfmt-support, qemu-user-static
#

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo ${SCRIPT_NAME}:"

source $SCRIPT_DIR/main.env

$SCRIPT_DIR/check-qemu.sh

if [ -f $CACHE/$DEBASE_BUILD_TAR ]; then 
  $ECHO "$CACHE/$DEBASE_BUILD_TAR exists, skip building"
  exit 0
fi

$ECHO "building $DEBASE_BUILD_TAR ..."

DIR=$TMP/debase-build

INCS=python2.7

rm -rf $DIR
mkdir -p $DIR
bash -c "$LOCALE_ENV \
  debootstrap --arch=arm64 --foreign --variant=buildd --include=$INCS buster $DIR"
cp -av /usr/bin/qemu-aarch64-static $DIR/usr/bin
chroot $DIR /bin/bash -c "$LOCALE_ENV /debootstrap/debootstrap --second-stage"
tar cf $CACHE/$DEBASE_BUILD_TAR --zstd -C $DIR .

$ECHO "$DEBASE_BUILD_TAR is ready"
