#!/bin/bash

# serial number from 
# manufacturer
# product
# host addr
# dev addr

HOST_ADDR="48:6f:73:74:50:43" # "HostPC"
DEV_ADDR="42:61:64:55:53:42" # "BadUSB"

configdir=/sys/kernel/config/usb_gadget/1
# usb_disk="/root/gen.iso"
mkdir $configdir && cd $configdir

echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB    # USB 2.0

echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

echo 1 > os_desc/use
echo 0xcd > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

mkdir -p strings/0x409
echo "123456" > strings/0x409/serialnumber
echo "Dingnan" > strings/0x409/manufacturer
echo "pan" > strings/0x409/product

mkdir -p functions/acm.usb0           # serial
mkdir -p functions/rndis.usb0         # rndis
mkdir -p functions/mass_storage.usb0  # mass_storage

mkdir -p configs/c.1
echo 250 > configs/c.1/MaxPower

echo $HOST_ADDR > functions/rndis.usb0/host_addr
echo $DEV_ADDR > functions/rndis.usb0/dev_addr
echo RNDIS > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

echo 1 > functions/mass_storage.usb0/lun.0/cdrom
echo 1 > functions/mass_storage.usb0/lun.0/ro
# echo $usb_disk > functions/mass_storage.usb0/lun.0/file

ln -s configs/c.1 os_desc
ln -s functions/rndis.usb0 configs/c.1/
ln -s functions/acm.usb0 configs/c.1/
ln -s functions/mass_storage.usb0 configs/c.1/

sleep 1

ls /sys/class/udc/ > UDC