# Layout

## eMMC Layout

```
$ rkdeveloptool wl 0x00     part.img        # MBR/DOS分区表
$ rkdeveloptool wl 0x40     idbloader.img   # spl
$ rkdeveloptool wl 0x4000   uboot.img       # uboot
$ rkdeveloptool wl 0x6000   trust.img       # atf
$ rkdeveloptool wl 0xF000   -               # zero
$ rkdeveloptool wl 0x10000  v.img           # btrfs volume
```

There is no need to flash 0xF000, but it should be zero-ed.

address (in sector) |size (in sector)|size (in byte)|file name|comment
-|-|-|-|-
0x00|64|32KB (or KiB)|part8g_cow_dos.img|partition table
0x40|||idbloader.img|rockchip spl
0x4000|||uboot.img|u-boot
0x6000|||trust.img|arm trusted firmware, with or without optee
0xF000|0x1000<br>4096|2 MiB or<br>2097152 bytes|uboot env
0x10000|0xE80000<br>15204352|7424 MiB or<br>7784628224 bytes|btrfs volume
0xE90000|||end (exclusive)

- MiB is MebiByte, 1024 x 1024 bytes
- MB is MegaByte, 1000 x 1000 bytes


UUID
+ btrfs volume: `037c3f75-80d5-40ae-b5dc-228fd42f1c2d`
+ init sub-volume: `5d244fa5-95af-4b0f-a68d-85997b1b9986`

init uboot env

```
2csv1_loader_l=5d244fa5-95af-4b0f-a68d-85997b1b9986
2csv1_loader_r=5d244fa5-95af-4b0f-a68d-85997b1b9986
```

```
2csv1_system_l=5d244fa5-95af-4b0f-a68d-85997b1b9986

2csv1_system_r=5d244fa5-95af-4b0f-a68d-85997b1b9986
```

## Btrfs Volume Layout

```
/
    boot/
        boot.cmd                        # u-boot script, text
        boot.scr                        # u-boot script, image 
        handover.env                    # u-boot env for handover
        tmp/                            # tmp folder for boot
    cowroot/
        refs/                           # git-like refs
            heads/
            tags/
        ro/                             # read-only volumes
            sub-vols-uuid///            
        rw/                             # read-write volumes
            sub-vols-uuid///
        tmp/
        tmpvol/                         # for creating new vol
```

设计说明

对于一个ro镜像，使用其内容的hash作为其标识是可能的。例如使用类似git的merkle tree来计算整个文件树的sha1值；这个方式的问题在于即时创建快照时，计算其特征值所需的算力和时间，对于系统启动而言这有困难，所以目前的设计决策仍然是使用uuid标识，而不是文件树的特征值。

ro目录存放所有只读快照，rw目录存放所有读写卷，tmpvol用于存放临时创建的读写卷，主要是升级时使用；不应该在tmpvol目录下创建临时文件。清空该目录时默认使用`btrfs subvolume delete`命令而不是`rm -rf`。

refs目录是仿照git的目录结构设计的，heads和git中的head/branch含义一致。

## cowroot script

cowroot script有两种实现方式，在initramfs hook中或者hijack /sbin/init，初步的实现采用后面的方式，实现和调试简单。

对于部署使用的ro模式，每次cowroot script直接抛弃和重建心的rw rootfs。

对于希望持久化使用rw rootfs的情况，在ro rootfs的设计下，并非一个简单的切换开关，它不能break u-boot的协议，所以实现上应该是先从rw rootfs上创建一个ro snapshot，然后向bootloader请求try这个snapshot。

理想的实现位置是在每次关机之前，但如果异常重启，就只能在cowroot script里做。

shutdown hook在systemd里是一个normalservice，脚本执行在ExecStop而不是ExecStart。

```
[Unit]
Description=...

[Service]
Type=oneshot
RemainAfterExit=true
ExecStop=<your script/program>

[Install]
WantedBy=multi-user.target
```

脚本逻辑大体是：
```
1. 检查autosnap标记，如果不存在则直接退出
2. snapshot rootfs -> ro
3. 发出请求
```

number| cell state|comment|may be seen by cowroot script
-|-|-|-
0|aa & aa|init/stable state|yes
1|aa & ab|system request b|yes (rollback)
2|ab & ab|u-boot try b|yes
3.1<br>3.2|ab & bb<br> ab & bc|system confirm b<br>system confirm b && request c|no<br>no
4.1<br>4.2|bb & bb<br>bc & bc|init/stable state (0)<br>u-boot try c (1)|yes<br>yes

## 2-Cell Shift

TBD

## RW Rootfs

如果需要象普通的读写方式持续使用Rootfs，在ro rootfs的实现下，该需求可以表述为：

在每个power cycle之后，自动snapshot rootfs得到ro副本，然后升级到该副本。

换句话说，持续使用一个镜像，和升级到一个新镜像，是一回事。

第一个问题是：

需要一个标记标定该逻辑，他应该是tag在snapshot上的标记？还是global switch？

第二个问题是：

实际使用中不能保证每次power cycle都有正常的关机流程；是否需要补救？如何补救？

> 在cowroot script里抢救未能snapshot的工作区是可能的，但是这里有个幻觉；
>
> 即时snapshot工作区获得的镜像，

第三个问题是：














