#### 安装并使用busybox

1. 下载解压
2. make menuconfig
3. make install，生成_install目录，这是由busybox构建的一个简单的用户环境
4. 在目录下编写init脚本，内核启动后会执行 `/init `，init脚本用于挂载内核调试必需的虚拟文件系统，启动终端
   例如

   ```
   #!/bin/sh

   mount -t proc none /proc
   mount -t sysfs none /sys
   mount -t devtmpfs devtmpfs /dev
   chown root:root flag
   chmod 400 flag
   exec 0</dev/console
   exec 1>/dev/console
   exec 2>/dev/console

   insmod /lib/modules/4.4.72/babydriver.ko
   chmod 777 /dev/babydev
   echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"
   setsid cttyhack setuidgid 1000 sh

   umount /proc
   umount /sys
   poweroff -d 0  -f
   ```
5. 进入生成的_install目录

   * 打包文件系统：
     `find . | cpio -o --format=newc > ../rootfs.img`
   * 解包
     `cpio -idmv < rootfs.img`

   生成的rootfs.img文件即是相应根文件系统

   `--format=newc` 指定 cpio 的打包格式为 `newc`，`newc`是 Linux 内核**唯一官方推荐 / 支持**的 cpio 格式
