#!/bin/bash

IMG=tmp/header.img

fallocate -l $((0x10000 * 0x200)) $IMG

# 0x00
dd if=rkbin/part8g_cow_dos.img of=$IMG bs=512 seek=0 conv=notrunc
# 0x40
dd if=rkbin/idbloader.img of=$IMG bs=512 seek=64 conv=notrunc
# 0x4000
dd if=rkbin/uboot.img of=$IMG bs=512 seek=16384 conv=notrunc
# 0x6000
dd if=rkbin/trust.img of=$IMG bs=512 seek=24576 conv=notrunc

mv $IMG header.img

