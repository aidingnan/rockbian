#!/bin/bash

set -e

if [ -d /sys/kernel/config/usb_gadget ]; then
  cd /sys/kernel/config/usb_gadget
  mkdir g1
  cd g1
  echo "0x1d6b" > idVendor
  echo "0x0104" > idProduct
  mkdir strings/0x409
  echo "0" > strings/0x409/serialnumber 
  echo "Dingnan" > strings/0x409/manufacturer 
  echo "Pocket Drive" > strings/0x409/product
  mkdir functions/acm.GS0
  mkdir functions/acm.GS1
  mkdir functions/acm.GS2
  mkdir configs/c.1
  mkdir configs/c.1/strings/0x409
  echo "CDC 3xACM" > configs/c.1/strings/0x409/configuration
  ln -s functions/acm.GS0 configs/c.1
  ln -s functions/acm.GS1 configs/c.1
  ln -s functions/acm.GS2 configs/c.1
  echo "ff580000.usb" > UDC
fi
