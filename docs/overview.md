# Overview

本项目提供的脚本和文档用于编译rk3328平台的emmc镜像。

- emmc分区方案
  - 使用dos分区表
  - 使用p/a/b三个ext4分区
    - 其中persistent分区存放uboot script和其他需要持久化的数据
    - a/b分区实现a/b升级
    - 创建分区表的脚本位于scripts目录下
    - 创建好的分区表头文件位于bin目录下
- 各种loader，包括：
  - rkusb loader
  - spl(idbloader)
  - uboot
  - trust
  - 编译好的二进制loader文件位于loaders目录下
- uboot script
  - 不同硬件或配置的uboot脚本位于boot目录下
- kernel
  - 以deb包格式作为delivery
  - config文件，文档，device tree文件
  - wifi/bt配置
- firmware
  - wifi firmware
  - bt firmware
- rootfs
  - 基于debian
- 所有内容合成的最终镜像和烧录方式



   
