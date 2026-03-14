### TP-link WDR类固件分析

家里路由器是TL-WDR7661千兆版，去官网上下载了对应的固件，发现被加密，LAMZ的分段数据

尝试在同型号设备之前发布的升级版本找一下解密程序，由于设备过新，只发布过一个版本的固件，只能是寻找一下同为WDR叫老版本的未加密固件有没有相关信息

先尝试分析一下TL-WDR8610版本的固件

#### 获取

固件下载：[TL-WDR8610 V3.0升级软件20190826_1.0.8](https://resource.tp-link.com.cn/pc/docCenter/showDoc?id=1634202008362963)

binwalk可以直接得到根文件系统

#### 分析

查找一下有关解密和升级的文件，暂时罗列了如下几个

```
./lib/upgrade
./usr/lib/lua/luci/view/admin/SysUpgradeConfirm.htm
./usr/lib/lua/luci/view/admin/SysUpgrade.htm
./usr/lib/lua/luci/controller/admin/cloud_sysupgrade.lua
./usr/lib/opkg/info/firmware_upgrade.list
./usr/lib/opkg/info/firmware_upgrade.control
./sbin/sysupgrade
./sbin/slpupgrade
./etc/sysupgrade.conf
```

##### slpupgrade

拖入IDA，先简单寻找程序入口点

![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20183930.png)

ftext函数反汇编后

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20184016.png)

_uClibc_main的实现无主体逻辑，查看汇编代码

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20184146.png)

mips传参前四个参数通过 `$a0-$a3` 来传递，实际上sub_403AB4是跳转的下一步地址，这就找到了程序入口点

寻找主要功能函数，shift+F12搜索一下含有bin的字符串

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20183131.png)

ctrl+x寻找引用，sub_402C6C函数中使用了大致分析了一下，这是一个升级失败的处理函数，先把调用链记录

```
ftext -> sub_403AB4 -> sub_402F80 -> sub_402C6C
```

从头开始分析，sub_403AB4中实现的功能大致为处理命令行参数调用对应函数

sub_402F80为系统资源申请成功时调用的核心升级固件的函数

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20204550.png)

程序内部存放RSA私钥，先sub_4023E4用来验证签名，之后就是报错输出，这还不是真正的处理逻辑，只是校验而已

看的东西比较多，换其他文件分析试试

##### sysupgrade

是段lua代码，实际上最终调用了slpupgrade，再回头去看slpupgrade![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20230444.png)

a2 即固件路径，有 a2 的参数 dword_417484 和 dword_417470

dword_417484 就是通过basename得到了固件文件名，几个使用 dword_417484 的函数都是输出错误信息的

dword_417470 = a2[optind]，即将指向固件路径指针存放到了全局变量dword_417470中

回归正题，继续分析sub_403AB4，通过寻找哪个分支无报错的消息输出函数，定位正确分支

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20233127.png)

sub_402238是对系统设备/dev/slp_flash_chrdev读取的操作

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20234654.png)

这里如果成功返回了一个v1，v1 = sub_400FCC(5, (int)&v3);

sub_402F80上边说过是RSA签名验证函数

v7（RSA校验成功） 和 v9（开始如果符合解密的参数，就是命令行参数带有效路径，不是-h这种）都为0，执行sub_40366C

调用链如下

```
sub_40366C -> sub_403310 -> sub_400DE0
```

而且下载固件一定会调用system执行系统命令，结合这一点定位到sub_403918函数

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-08%20210557.png)

看以看到执行了 `/etc/init.d/rcS` 进行了重启，看看 `/etc/init.d/rcS`

![](https://raw.githubusercontent.com/soskong/Image/main/1772975330851.png)

原来是批量执行 `/etc/rc.d/` 下的脚本，那么这个slpupgrade原来是通过重启脚本更新，并不是更新固件
