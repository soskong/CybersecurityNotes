#### qemu启的内核中运行的程序

模拟固件通常使用qemu启动一个内核，在里面运行固件

1. 下载并启动对应架构的gdb调试程序
2. qemu启动脚本中添加 `-s -S` 参数



#### 调试qemu模拟运行的程序

用file命令查看该文件的架构，对于mips机构，有大小端之分，LSB即小端，使用qemu-mipsel模拟，MSB即大端，使用qemu-mips模拟。

程序运行：`qemu-mipsel -g 9999 -L . ./htdocs/cgibin`

gdb中

```
set architecture mips
set endian little
set sysroot /home/i/iot/dlink/d815/squashfs-root
file /home/i/iot/dlink/d815/squashfs-root/htdocs/cgibin

```

#### 参数

```
-0 phpcgi  	# 强行使main函数的argv[0]为phpcgi
```
