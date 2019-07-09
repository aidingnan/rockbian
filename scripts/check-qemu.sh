#!/bin/bash

MAJOR=3
MINOR=1
VER_STRING=$(qemu-aarch64-static --version | grep version | awk '{print $3}')

IFS='.' read -ra ver_array <<< "$VER_STRING"

if [[ "${ver_array[0]}" < "$MAJOR" ]]; then
  echo "ERROR: minimal qemu version 3.1.x"
  exit 1
fi

if [[ "${ver_array[1]}" < "$MINOR" ]]; then
  echo "ERROR: minimal qemu version 3.1.x"
  exit 1
fi
