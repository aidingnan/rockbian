## 内核配置说明

### WLAN

支持wlan要求内核使能如下配置：

**CFG80211, CFG80211_DEFAULT_PS, CFG80211_WEXT**

```
Networking support > Wireless
    <M>   cfg80211 - wireless configuration API
    ....
    [ ]     enable powersave by default
    [*]     cfg80211 wireless extensions compatibility
```

应该选择为module(`[M]`)编译，否则需要修改initramfs把firmware放进去；如果选择为内置模块又不在initramfs里提供firmware会观察到错误并且在磁盘根文件系统挂载时并不会再次触发probe加载固件，必须bind/unbind driver。

CFG80211_DEFAULT_PS缺省为y，去掉该选项。

CFG80211_WEXT选项不是必须的，一些linux wifi网络配置命令需要该接口工作。

**BRCMFMAC, BRCMFMAC_SDIO, BRCM_TRACING, BRCMDBG**

```
Device Drivers > Network device support > Wireless LAN
    [*]   Broadcom devices
    <M>     Broadcom FullMAC WLAN driver
    [*]     SDIO bus interface support for FullMAC driver
    ....
    [*]     Broadcom device tracing
    [*]     Broadcom driver debug functions
```

BRCM_TRACING使用kernel的ftrace特性；在ftrace未开启时会有微小的overhead，内核建议打开该选型以利于开发者调试；

BRCMDBG可以输出更多的debug信息；modprobe可以提供debug参数，该参数使用bitmask方式打开debug信息，例如：

```
modprobe brcmfmac debug=0xffff
```

firmware文件为：`/lib/firmware/brcm/brcmfmac4356-sdio.bin`，armbian自带了该文件；由`linux-firmware`包提供；

```

$ dmesg | grep brcmfmac

brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4356-sdio for chip BCM4356/2
brcmfmac mmc0:0001:1: Direct firmware load for brcm/brcmfmac4356-sdio.clm_blob failed with error -2
brcmfmac: brcmf_c_process_clm_blob: no clm_blob available (err=-2), device may have limited channels available
brcmfmac: brcmf_c_preinit_dcmds: Firmware: BCM4356/2 wl0: May 14 2014 19:51:52 version 7.35.17 (r477908) FWID 01-2ed3ee81
```

TODO 补充brcmfmac的dts配置说明

其他：

linux内核支持从userspace强制bind/unbind driver；对于sdio来说没有别的办法强制probe，使用bind/unbind是一个办法：

```
# unbind sdio host driver
echo -n "ff510000.dwmmc" > /sys/devices/platform/ff510000.dwmmc/driver/unbind
# bind sdio host driver
echo -n "ff510000.dwmmc" > /sys/devices/platform/ff510000.dwmmc/subsystem/drivers/dwmmc_rockchip/bind
```

### Bluetooth

**SERIAL_DEV_BUS, SERIAL_DEV_CTRL_TTYPORT**

```
Device Drivers > Character devices
    <*>     Serial device bus --->
```

该选项必须为y，不可为M。

```
Device Drivers > Character devices > Serial device bus
    [*]     Serial device TTY port controller (NEW)
```

**BT_HCIUART_BCM**

```
Networking support > Bluetooth subsystem support > Bluetooth device drivers
    <M> HCI UART Driver
    -*-   UART (H4) protocol support
    ...
    [*] Broadcom protocol support
```

BT_HCIUART_BCM依赖serial device bus和tty port controller选项；需先设置SERIAL_DEV_BUS。

BT_HCIUART_BCM需设置为M，否则需要在initramfs中添加固件。

+ 注意该配置页面上有两个Broadcom protocol support，应选择对应BT_HCIUART_BCM的；

### Disable PMU Clock Driver

**MFD_RK808**

```
Device Drivers > Common Clock Framework
    < > Clock driver for RK805/RK808/RK818
```

rockchip提供的config文件勾选了该选项，但驱动有bug（可能是对应rk808是ok的，但是对rk805不工作），如果使用pmu的32kHz时钟为wifi/bt module提供lpo clock，必须去除该勾选。

### Filesystem Support

让内核内置支持btrfs和overlayfs.

**BTRFS_FS**

```
File systems > 
    <*> Btrfs filesystem support
```

**OVERLAY_FS**

```
File systems > 
    <*> Overlay filesystem support
    ...
    [*]   Overlayfs: follow redirects even if redirects are turned off (NEW)
    ...
```

### ZRAM

**ZRAM, ZRAM_WRITEBACK**

```
Device Drivers > Block devices >
    <*>   Compressed RAM block device support
    [*]     Write back incompressible or idle page to backing device
```

### USB Gadget

```
Device Drivers > USB support > USB Gadget
    [ ]   Serial gadget console support
    <*>   USB Gadget precomposed configurations ---> 
        (X) Serial Gadget (with CDC ACM and CDC OBEX support)
```

Serial gadget console support（CONFIG_U_SERIAL_CONSOLE）一定不要勾选。如果勾选该选项并且在kernel cmdline里传递CONSOLE=ttyGS0，则设备插在充电器上时无法启动，内核一直在等待ttyGS0；网上很多教程在pi和linux-sunxi上使用这种配置方式，但是在RK3328上有上述问题。

正确的做法是不再内核里提供CONFIG_U_SERIAL_CONSOLE配置，但是内置G_SERIAL支持；不在cmdline中提供console=ttyGS0，而是创建一个getty@ttyGS0.service提供console。该方法不会导致启动等待ttyGS0的console，而在设备热插拔时仍然可以通过ttyGS0 (host-side ttyACM0)提供console服务。

```
ln -s /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@ttyGS0.service
```

## Device Tree

### USB3 

There is no usb3 support in mainline kernel. The following block should be added into rk3328.dtsi, usually after the usb host0 ohci block.

```
  usbdrd3: usb@ff600000 {
    compatible = "rockchip,rk3328-dwc3", "rockchip,rk3399-dwc3";
    clocks = <&cru SCLK_USB3OTG_REF>, <&cru SCLK_USB3OTG_SUSPEND>,
       <&cru ACLK_USB3OTG>;
    clock-names = "ref_clk", "suspend_clk",
            "bus_clk";
    #address-cells = <2>; 
    #size-cells = <2>; 
    ranges;
    status = "disabled";

    usbdrd_dwc3: dwc3@ff600000 {
      compatible = "snps,dwc3";
      reg = <0x0 0xff600000 0x0 0x100000>;
      interrupts = <GIC_SPI 67 IRQ_TYPE_LEVEL_HIGH>;
      dr_mode = "otg";
      phy_type = "utmi_wide";
      snps,dis_enblslpm_quirk;
      snps,dis-u2-freeclk-exists-quirk;
      snps,dis_u2_susphy_quirk;
      snps,dis_u3_susphy_quirk;
      snps,dis-del-phy-power-chg-quirk;
      snps,dis-tx-ipgap-linecheck-quirk;
      status = "disabled";
    };   
  };
```

### add rk3328-backus.dts

Add this line to Makefile in `arch/arm64/boot/dts/rockchip`

```make
dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3328-backus.dtb
```

# Troubleshooting

most frequently encountered problem for brcmfmac:

1. bad 3.3V Vbat
2. bad sdio trace routing
   

most frequently encoutered problem for hciuart_bcm:

- no problem

