#!/bin/sh

cd /sys/kernel/config/usb_gadget/
mkdir -p g1
cd g1

echo 0x04b3 > idVendor
echo 0x4010 > idProduct
echo 0x0100 > bcdDevice
mkdir -p strings/0x409

# TODO use atecc number
echo "badc0deddeadbeef" > strings/0x409/serialnumber
echo "dingnan" > strings/0x409/manufacturer
echo "IntelliDrive" > strings/0x409/product

# RNDIS
mkdir -p configs/c.1/strings/0x409
echo "0x80" > configs/c.1/bmAttributes
echo 250 > configs/c.1/MaxPower
echo "RNDIS network" > configs/c.1/strings/0x409/configuration
echo "1" > os_desc/use
echo "0xcd" > os_desc/b_vendor_code
echo "MSFT100" > os_desc/qw_sign

mkdir -p functions/rndis.usb0
echo "RNDIS" > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo "5162001" > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

# CDC ECM
mkdir -p configs/c.2/strings/0x409
echo "ECM network" > configs/c.2/strings/0x409/configuration
echo 250 > configs/c.2/MaxPower

mkdir -p functions/ecm.usb0

# Link everything and bind the USB device
ln -s configs/c.1 os_desc
ln -s functions/rndis.usb0 configs/c.1
ln -s functions/ecm.usb0 configs/c.2

ls /sys/class/udc > UDC
