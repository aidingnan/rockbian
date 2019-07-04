#!/bin/bash

# debootstrap, binfmt-support, qemu-user-static

set -e

SCRIPT_DIR=$(dirname "$0")
SCROPT_NAME=$(basename "$0")
ECHO="echo ${SCRIPT_NAME}: "

source $SCRIPT_DIR/main.env

if [ -f $CACHE/$DEBASE_BUILD_TAR ]; then 
  $ECHO "$CACHE/$DEBASE_BUILD_TAR exists, skip building"
  exit 0
fi

WORKDIR=$TMP/debase-build

rm -rf $WORKDIR
mkdir -p $WORKDIR
debootstrap --arch=arm64 --foreign --include=python2.7 --variant=buildd buster $WORKDIR
cp -av /usr/bin/qemu-aarch64-static $WORKDIR/usr/bin
chroot $WORKDIR /bin/bash -c "LANG=C /debootstrap/debootstrap --second-stage"
tar czf $CACHE/$DEBASE_BUILD_TAR -C $WORKDIR .
