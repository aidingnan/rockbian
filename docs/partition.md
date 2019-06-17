# Partition

1. Rockchip官方文档推荐使用GPT；
2. `rkdeveloptool`创建分区表的代码有bug；
3. uboot缺省从mmc第一个分区开始寻找boot script，假定其为ext文件系统；
4. GPT在磁盘最末的33个sector存储第二分区表；

综上，使用GPT并不如使用MBR方便；idbloader和u-boot并不强制需要GPT。

## 8GB EMMC

实际容量是15269888(0xE90000)块或7,818,182,656 bytes，与三星Datasheet中的数据吻合，也和Kernel启动后看到的block device大小一致，分3个Primary分区，位置的大小如下。

|Device|Start|End|Sectors|Size|Id|Type|
|-|-|-|-|-|-|-|
|image1|65536(0x10000)|2162687|2097152|1G|83|Linux|
|image2|2162688(0x210000)|8716287|6553600|3.1G|83|Linux|
|image3|8716288(0x850000)|15269887|6553600|3.1G|83|Linux|

## 创建分区表

可以用脚本创建分区表，截取头部64(0x40)个sector，用rkdeveloptool写入emmc即可。


```bash
# scripts/part8g_ab.sh

#!/bin/bash

IMG=bin/part8g_ab.img

mkdir -p bin 

rm -rf $IMG
fallocate -l 7818182656 $IMG

fdisk $IMG << EOF
o
n
p
1
65536
2162687
n
p
2
2162688
8716287
n
p
3
8716288
15269887
w
EOF

truncate -s $((64 * 512)) $IMG

fdisk -l $IMG
```

## 分区使用

第一个分区称p分区，用于保存持久化数据，uboot的boot script（boot.cmd和boot.scr）位于该分区的`/boot`目录下；该分区也可以用于启动recovery模式。

第二个和第三个分区分别称a分区和b分区，都是rootfs分区，用于实现a/b升级。

 21 part1 0cbc36fa-3b85-40af-946e-f15dce29d86b
 22 part2 689b853f-3749-4055-8359-054bd6e806b4
 23 part3 9bec42be-c362-4de0-9248-b198562ccd40

# Partition (cow)