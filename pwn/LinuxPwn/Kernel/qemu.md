#### 安装

1. 打开虚拟机虚拟化支持，设置-处理器-虚拟或Intel或AMD
2. 下载对应源码：`wget https://download.qemu.org/qemu-8.2.1.tar.xz`
3. 解压并进入对应目录：`tar xvJf qemu-8.2.1.tar.xz`
4. 安装所需依赖

   ```
   apt install libslirp-dev
   apt install re2c
   apt install ninja-build
   apt install build-essential zlib1g-dev pkg-config libglib2.0-dev
   aptinstall binutils-dev libboost-all-dev autoconf libtool libssl-dev libpixman-1-dev libpython-dev python-pip python-capstone virtualenv
   apt install libpixman-1-dev
   apt install bison flex
   apt install meson
   apt install libpixman-1-dev
   apt-get install libpcap-dev libnids-dev libnet1-dev
   apt-get install libattr1-dev
   apt-get install libcap-ng-dev
   ```
5. 执行 `sudo ./configure --enable-slirp`，不然会遇到报错

   ```
   qemu-system-x86_64: -nic user,model=virtio: network backend 'user' is not compiled into this binary
   ```

   ```
   “user”网络后端由“slirp”库提供;当 QEMU 二进制文件是在没有编译 slirp 支持的情况下构建的时，您会收到此消息。

   正如 7.2 更新日志中所述，QEMU 不再提供 slirp 模块及其源代码的副本。相反，在配置和构建 QEMU 之前，您需要确保已经安装了发行版的 libslirp 开发包（可能称为 libslirp-devel 或 libslirp-dev 或类似的东西）。您至少需要 libslirp 4.7 或更高版本。

   QEMU对需要一些构建时依赖关系的可选功能的配置约定是：

   默认情况下，检查依赖项，如果找到它，则构建该功能
   如果传递了 --enable-foo，请检查依赖项，如果缺少依赖项，则失败配置并显示错误
   如果传递了 --disable-foo，请不要检查，也不要在功能中构建
   因此，如果您没有依赖项，您可以传递 configure 以强制它给您一个错误，作为检查您是否为 libslirp 安装了正确的系统包的一种方式。--enable-slirp
   ```
6. 构建：`sudo make`
7. 安装：`sudo make install`

#### 启动参数

```
-kernel bzImage		指定
-initrd rootfs.img	指定根文件系统

-append 'console=ttyS0 root=/dev/ram oops=panic panic=1'
console=ttyS0		将输出映射到终端
root参数设定了根文件系统所在设备
root=/dev/ram		根文件系统在 initramfs，使用内存设备
root=/dev/sda rw	使用-hda将根文件系统挂载为一个 SATA 硬盘，而Linux中第一个SATA硬盘的路径为/dev/sda，并通过rw标识来给予可读写权限
oops=panic		内核出错直接等同于panic，直接重启
panic=1			panic 1 秒后自动重启
nokaslr或者kaslr	是否开启内核随机化
nosmep			关闭smep保护
kpti=1 			开启 KPTI
nopti			关闭 KPTI

--nographic		禁用图形窗口，所有 I/O 走终端（ttyS0）
-monitor /dev/null	禁用 QEMU monitor：QEMU monitor即qemu自带的交互式界面，禁用 QEMU monitor避免快捷键输入被qemu抢走
-m 64M			设定运行内存大小 
-smp cores=1,threads=1	CPU 拓扑，1 核 1 线程
-cpu kvm64,+smep	使用x86_64架构cpu，指定相关保护机制
+smep 			开启 SMEP
+smap			开启 SMAP

-s			表示 -gdb tcp::1234，即在 1234 端口开启一个 gdbserver







```


对于从哪里挂载根文件系统

| root 参数        | 根 FS 在哪 | 是否持久 | 典型用途  |
| ---------------- | ---------- | -------- | --------- |
| `/dev/ram`     | 内存       | ❌       | CTF / pwn |
| `/dev/sda`     | SATA 硬盘  | ✅       | 普通系统  |
| `/dev/vda`     | VirtIO     | ✅       | QEMU      |
| `/dev/mmcblk*` | SD/eMMC    | ✅       | 嵌入式    |
| UUID/LABEL       | 任意       | ✅       | 生产系统  |
