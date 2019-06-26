#!/bin/bash

# debootstrap, binfmt-support, qemu-user-static

set -e

SCRIPT_DIR=$(dirname "$0")

source $SCRIPT_DIR/main.env

if [ -f $CACHE/$DEBASE_TESTING ]; then exit; fi

DEBASE=$TMP/debase-testing

rm -rf $DEBASE
mkdir -p $DEBASE
debootstrap --arch=arm64 --foreign --variant=minbase buster $DEBASE
cp -av /usr/bin/qemu-aarch64-static $DEBASE/usr/bin
chroot $DEBASE /bin/bash -c "LANG=C /debootstrap/debootstrap --second-stage"
tar czf $CACHE/$DEBASE_BUILD -C $DEBASE .
