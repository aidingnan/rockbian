#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo $SCRIPT_NAME:"

for line in $@; do 
  eval "$line"
done

source $SCRIPT_DIR/main.env
source $WINAS_ENV  
source $WINASD_ENV

list="$DEBASE_TAR $DEBASE_BUILD_TAR $KERNEL_DEB $ROOTFS_TAR $WINAS_TAR $WINAS_DEV_TAR $WINASD_TAR $WINASD_DEV_TAR $VOL_TAR"
for file in $list; do
  $SCRIPT_DIR/upload-asset.sh token=$token tag=$tag filename=$CACHE/$file
done 
