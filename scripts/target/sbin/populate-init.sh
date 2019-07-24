#!/bin/bash

set -e

if [ -z "$1" ]; then 
  echo "dir not provided"
  exit 1
fi

#
# DIR
#   init -> init.0    # symlink
#   init.0            # directory
#
DIR=$1
INIT="$DIR/init"
INIT0="$DIR/init.0"
TMP="$DIR/tmp"

if [ -h $DIR/init ]; then exit 0; fi

{ 
  SN=$(atecc -b 1 -c serial) 
} || { 
  SN=$(uuid -v4) 
}
if [ -z "$SN" ]; then exit 1; fi

USN=$(encode-usn $SN)
hash=$(echo -n "$USN" | sha256sum | cut -c 1-64)

HOSTNAME="pan-${USN:0:4}"
MACHINE_ID=${hash:0:32}

mac5="${hash:32:2}:${hash:34:2}:${hash:36:2}:${hash:38:2}:${hash:40:2}"
rm -rf $INIT
rm -rf $INIT0
rm -rf $TMP

mkdir $TMP

echo "$SN" > $TMP/sn
echo "$USN" > $TMP/usn
echo "$HOSTNAME" > $TMP/hostname
echo "$MACHINE_ID" > $TMP/machine-id
cat > $TMP/usb0.env << EOF
SERIAL_NUMBER=$USN
MANUFACTURER="Shanghai Dingnan Co., Ltd"
PRODUCT="Smart Drive"
HOST_ADDR="82:$mac5"
DEV_ADDR="86:$mac5"
EOF

mv $TMP $INIT0
ln -s init.0 $INIT

