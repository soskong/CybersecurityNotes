#### afl fuzz固件

##### qemu模式

```
$ QEMU_LD_PREFIX=./squashfs-root/ afl-fuzz -Q -i squashfs-root/bmp-input/ -o squashfs-root/bmp-output/ -- ./squashfs-root/usr/bin/bmp2tiff @@ /dev/null # root权限下
# -Q：适用qemu模式
# -i：输入文件夹
# -o：输出文件夹
# @@：表示将用来替换的样本
# /dev/null：忽略错误信息
```


```
QEMU_LD_PREFIX=./squashfs-root/ afl-fuzz -Q -i ./squashfs-root/input-json/ -o ./squashfs-root/output-json/ -- ./squashfs-root/usr/sbin/jsonparse @@ 
```

##### Harness fuzz

使用stdin代替socket字节流加速fuzz，待

#### 参考


[FirmAFL-CSDN博客](https://blog.csdn.net/leiwuhen92/article/details/132801050)

[记录一次失败的固件 fuzz - 二进制咸鱼的自我救赎](https://chenx6.github.io/post/fail_firm_fuzz/)
