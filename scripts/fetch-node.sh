#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")

source $SCRIPT_DIR/main.env

NODE_URL=https://nodejs.org/dist/$NODE_TAG/$NODE_TAR

if [ -f $CACHE/$NODE_TAR ]; then 
  echo "[${SCRIPT_NAME}] $CACHE/$NODE_TAR exists, skip downloading."
  exit
fi

wget -O $TMP/$NODE_TAR $NODE_URL
mv $TMP/$NODE_TAR $CACHE/$NODE_TAR
echo "[${SCRIPT_NAME}]" $CACHE/$NODE_TAR is ready."

