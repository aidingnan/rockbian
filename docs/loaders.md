# Loaders

一共有4个loader的二进制文件需要生成。

* rkusb loader
* idbloader
* uboot
* trust, arm trust firmware

rkusb loader用于使用rkusb工具（rkdeveloptool或upgrade_tool）时，下载到处理器内存中执行rkusb协议；使用rksub工具时该操作必须是第一步，否则除了ld命令（列出rkusb设备），其他命令均不可用。

idbloader是spl，类似u-boot的tpl，但rockchip提供了两个二进制文件实现同样功能，包括初始化内存和载入u-boot。

uboot是u-boot loader。

trust是arm trust firmware。

## 生成

rockchip提供了原始的二进制文件和生成最终loader镜像文件的工具。

name | source | ini file | tool (provider)
-|-|-|-|
rk3328_loader_v1.16.250.bin | ddr, usbplug, miniloader | RK3328MINIALL.ini | boot_merger (rk)
idbloader.img | ddr, miniloader | - | mkimage (u-boot tools)
uboot.img | u-boot-dtb.bin (compiled from u-boot) | - | loaderimage (rk)
trust.img | bl31, bl32 (optional?) | RK3328TRUST.ini | trust_merger (rk)

其中uboot.img仅与u-boot源码和配置有关，与rk提供的二进制无关；其他三者则正好相反，仅与rk提供的二进制有关，与u-boot无关。

### rkusb loader

ini原始文件参见 https://github.com/rockchip-linux/rkbin/blob/master/RKBOOT/RK3328MINIALL.ini

```
# in loaders/

./boot_merger RK3328MINIALL.ini
```

生成的文件名，例如rk3328_loader_v1.16.250.bin，其中v1.16是ddr的版本，250是usbplug和miniloader的版本（2.50）。

### idbloader

```
DDR=rk3328_ddr_333MHz_v1.16.bin
MINILOADER=rk322xh_miniloader_v2.50.bin

mkimage -n rk3328 -T rksd -d $DDR idbloader.img
cat $MINILOADER >> idbloader.img
```

mkimage在linux distro里由u-boot-tools包提供，u-boot源码目录下的tools目录下也有该工具。

### uboot

u-boot需要源码编译，生成loader需要u-boot编译后得到的u-boot-dtb.bin文件。

```
./loaderimage --pack --uboot /path/to/u-boot-dtb.bin uboot.img 0x200000
```

### trust

ini原始文件参见 https://github.com/rockchip-linux/rkbin/blob/master/RKTRUST/RK3328TRUST.ini

rockchip官方提供的trust.ini文件使用了bl31和bl32，后者不是必须的。

## u-boot编译

可以使用最新的mainline u-boot。从u-boot官方的ftp服务器下载源码包，选择2019.04版：

```
ftp://ftp.denx.de/pub/u-boot/u-boot-2019.04.tar.bz2
```

### 编译配置文件

file path | comment
-|-
configs/evb-rk3328_defconfig | 使用rk3328 evb的编译配置
arch/arm/dts/rk3328-evb.dts | 使用rk3328 evb的device tree

### 编译步骤

#### 1. 修改dts

删除gmac配置；会和wifi/bt module产生冲突；

```

 34   gmac_clkin: external-gmac-clock {
 35     compatible = "fixed-clock";
 36     clock-frequency = <125000000>;
 37     clock-output-names = "gmac_clkin";
 38     #clock-cells = <0>;
 39   };

103 &gmac2io {
104   phy-supply = <&vcc_phy>;
105   phy-mode = "rgmii";
106   clock_in_out = "input";
107   snps,reset-gpio = <&gpio1 RK_PC2 GPIO_ACTIVE_LOW>;
108   snps,reset-active-low;
109   snps,reset-delays-us = <0 10000 50000>;
110   assigned-clocks = <&cru SCLK_MAC2IO>, <&cru SCLK_MAC2IO_EXT>;
111   assigned-clock-parents = <&gmac_clkin>, <&gmac_clkin>;
112   pinctrl-names = "default";
113   pinctrl-0 = <&rgmiim1_pins>;
114   tx_delay = <0x26>;
115   rx_delay = <0x11>;
116   status = "okay";
117 };

```

#### 2. 选择config

```
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- evb-rk3328_defconfig
```

#### 3. 修改config

```
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- menuconfig
```


修改CONFIG_BOOTDELAY为0

```
    (0) delay in seconds before automatically booting
```

关闭网络支持，NET=n

```
    [ ] Networking support  ----
```

保存修改后的config

#### 4. 编译

```
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- all
```

生成的文件中包括制作uboot.img所需的`u-boot-dtb.bin`文件。

#### rkdeveloptool

```
# 枚举rkusb设备，应看到打印信息
$ rkdeveloptool ld

# 下载rkusb loader
$ rkdeveloptool db rk3328_loader_v1.14.249.bin

$ rkdeveloptool wl 0x00     part.img        # MBR/DOS分区表
$ rkdeveloptool wl 0x40     idbloader.img   # spl
$ rkdeveloptool wl 0x4000   uboot.img       # uboot
$ rkdeveloptool wl 0x6000   trust.img       # atf
$ rkdeveloptool wl 0x10000  p.img           # partition p (persistent)
$ rkdeveloptool wl 0x210000 a.img           # partition a (rootfs a)
```
####


```
=> bdinfo
arch_number = 0x0000000000000000
boot_params = 0x0000000000000000
DRAM bank   = 0x0000000000000000
-> start    = 0x0000000000200000
-> size     = 0x000000003fe00000
baudrate    = 1500000 bps
TLB addr    = 0x000000003fff0000
relocaddr   = 0x000000003ff4a000
reloc off   = 0x000000003fd4a000
irq_sp      = 0x000000003df3aee0
sp start    = 0x000000003df3aee0
Early malloc usage: 498 / 800
fdt_blob    = 0x000000003df3aef8
```

```
-> start        = 0x00200000
-> size         = 0x3fe00000

scriptaddr      =0x00500000
pxefile_addr_r  =0x00600000
fdt_addr_r      =0x01f00000
kernel_addr_r   =0x02080000
ramdisk_addr_r  =0x04000000

# safe ???
                =0x08000000 

# if set this is the address of the control flattened device tree used by U-Boot when CONFIG_OF_CONTROL is defined.
fdtcontroladdr  =0x3df3aef8
```


