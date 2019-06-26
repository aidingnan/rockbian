#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")

source $SCRIPT_DIR/main.env

NODE_URL=https://nodejs.org/dist/$NODE_TAG/$NODE_TAR

if [ -f $CACHE/$NODE_TAR ]; then exit; fi

wget -O $CACHE/$NODE_TAR $NODE_URL
