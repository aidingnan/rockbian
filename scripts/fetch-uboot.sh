#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo $SCRIPT_NAME:"

source $SCRIPT_DIR/main.env

# TODO rename branch?

SHA=$(curl -s https://api.github.com/repos/aidingnan/u-boot/commits/dingnan | jq '.sha')
if [[ ! "$SHA" =~ ^\"[a-f0-9]{40}\"$ ]]; then
  $ECHO "bad sha: $SHA"
  exit 1
fi

SHA=${SHA:1:40}
if  [ -f $UBOOT_ENV ]; then
  source $UBOOT_ENV
  if [ "$UBOOT_SHA" == "$SHA" ] && [ -f $CACHE/$UBOOT_ZIP ]; then
    $ECHO "$UBOOT_ZIP is up-to-date, skip downloading." 
    exit
  fi
fi

$ECHO "Downloading uboot source @ commit ${SHA:0:7}"

UBOOT_SHA=$SHA
UBOOT_ZIP=u-boot-${SHA:0:7}.zip
UBOOT_BIN=u-boot-dtb-${SHA:0:7}.bin
UBOOT_IMG=u-boot-${SHA:0:7}.img

TMPFILE=tmp/tmp-uboot

wget https://github.com/aidingnan/u-boot/archive/${UBOOT_SHA:0:7}.zip -O $TMPFILE

mv $TMPFILE $CACHE/$UBOOT_ZIP

cat > $UBOOT_ENV << EOF
UBOOT_SHA=$UBOOT_SHA
UBOOT_ZIP=$UBOOT_ZIP
UBOOT_BIN=$UBOOT_BIN
UBOOT_IMG=$UBOOT_IMG
EOF

$ECHO "$UBOOT_ZIP is ready"
