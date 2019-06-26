#!/bin/bash

# debootstrap, binfmt-support, qemu-user-static

CACHE=cache
DEBASE=tmp/debase-sandbox

# tzdata already in base
INCS+=python-minimal,build-essential

rm -rf $DEBASE
mkdir -p $DEBASE
debootstrap --arch=arm64 --foreign --include=$INCS buster $DEBASE
cp -av /usr/bin/qemu-aarch64-static $DEBASE/usr/bin
chroot $DEBASE /bin/bash -c "LANG=C /debootstrap/debootstrap --second-stage"

mkdir -p cache
tar czf $CACHE/debase-sandbox.tar.gz -C $DEBASE .
