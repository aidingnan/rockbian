# Prerequisite

## rkdeveloptool

rockchip芯片支持通过usb烧录emmc镜像。

rockchip提供了`upgrade_tool`和`rkdeveloptool`两个工具实现emmc烧录；其中`upgrade_tool`有windows和linux版本，在linux上可使用console模式；`rkdeveloptool`是独立的linux命令。这两个工具在rockchip的rkbin项目中均有二进制版本提供。

本文档使用`rkdeveloptool`作为烧录工具；同时要求使用者使用rkdeveloptool的最新源码编译，在rkbin中的二进制版本较老，有些新特性不支持。

## qemu和binfmt

本项目在x86 host上直接用chroot执行arm64代码，需要安装qemu和binfmt包实现支持。在Ubuntu 18.04系统上无须额外配置。

## 交叉编译工具链

交叉编译内核和uboot需要aarch64-gnu-linux-gcc工具链。

