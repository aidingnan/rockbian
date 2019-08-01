#!/bin/bash

set -e

DATA_DIR=/run/cowroot/root/data

if [ -e $DATA_DIR/root/engineering ]; then
  # engineering mode, forcefully replace authorized_keys 
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  rm -rf /root/.ssh/authorized_keys
  cat /run/cowroot/root/data/ssh/keys/id_rsa.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys 
elif [ ! -h $DATA_DIR/root ]; then
  # non-root mode, keys not allowed
  rm -rf /root/.ssh/authorized_keys  
fi

