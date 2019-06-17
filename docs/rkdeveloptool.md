# rkdeveloptool

## 源码编译

推荐使用源码编译；编译前需要安装如下包：

```
sudo apt-get install libudev-dev libusb-1.0-0-dev dh-autoreconf pkg-config
```

配置与编译过程

```
git clone https://github.com/rockchip-linux/rkdeveloptool
cd rkdeveloptool
autoreconf -i
./configure
make
sudo make install
```

如果遇到下述错误，是因为未安装`pkg-config`；安装该包之后需要重新执行`autoreconf`。

```
./configure: line 4449: syntax error near unexpected token `LIBUSB1,libusb-1.0'
./configure: line 4449: `PKG_CHECK_MODULES(LIBUSB1,libusb-1.0)'
```

## 预编译

rkbin代码池的`tools`内有预编译版本，版本较老，如果遇到问题需自行编译。