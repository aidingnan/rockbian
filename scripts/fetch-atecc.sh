#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
ECHO="echo ${SCRIPT_NAME}: "

source $SCRIPT_DIR/main.env

URL=https://github.com/aidingnan/atecc-util/releases/download/v1.0.0/atecc

if [ -f $CACHE/$ATECC_BIN ]; then 
  $ECHO "$CACHE/$ATECC_BIN exists, skip downloading."
  exit
fi

rm -rf $TMP/$ATECC_BIN
wget -O $TMP/$ATECC_BIN $URL
mv $TMP/$ATECC_BIN $CACHE/$ATECC_BIN
$ECHO "$CACHE/$ATECC_BIN is ready."


