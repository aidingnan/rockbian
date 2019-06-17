#!/bin/bash

IMG=bin/part8g_cow_dos.img

mkdir -p bin 

rm -rf $IMG

# 0xE90000 * 0x200 (512) -> 7818182656
fallocate -l 7818182656 $IMG

# 0x10000 -> 65536
# 0xE90000 - 1 -> 15269887
fdisk $IMG << EOF
o
n
p
1
65536
15269887
w
EOF

truncate -s $((64 * 512)) $IMG

fdisk -l $IMG
