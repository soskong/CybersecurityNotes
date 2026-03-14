WDR-7661是一种搭载了Vxworks操作系统的路由器

#### 固件分析

binwalk分析bin文件![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-10%20102626.png)

固件由一个 `uImage header` 和一堆LZMA格式压缩的数据组成，arm架构设备，先将uboot loader提取出来

```
dd if=./TL-WDR7661.bin of=./of.raw bs=1 skip=512 count=66048
```

之后的 0x10400-0x179440存放了很大的数据，一般来说这也是主程序所在，提取

```
dd if=./TL-WDR7661.bin of=./main.lzma bs=1 skip=66560 count=1478720
```

提取完解压缩

```
lzma -d main.lzma
```

binwalk再分析一下，确定是小端程序

```
i@i-virtual-machine:~/iot/TP-link/TL-WDR7661$ binwalk ./main

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
50149         0xC3E5          Certificate in DER format (x509 v3), header length: 4, sequence length: 1280
2587098       0x2779DA        MPEG transport stream data
3592682       0x36D1EA        StuffIt Deluxe Segment (data): fDomain
3592697       0x36D1F9        StuffIt Deluxe Segment (data): fPort
3612048       0x371D90        HTML document header
3612113       0x371DD1        HTML document footer
3632813       0x376EAD        Neighborly text, "neighbor[%02x:%02x:%02x:%02x:%02x:%02x] purge ALL BH). Found new device by link metrics response: %02x:%02x:%02x:%02x:%02x:%02x"
3632979       0x376F53        Neighborly text, "neighbor: %02x:%02x:%02x:%02x:%02x:%02xesponse without device info"
3633255       0x377067        Neighborly text, "neighbor device[%02x:%02x:%02x:%02x:%02x:%02x] can't find bh iface<%02x:%02x:%02x:%02x:%02x:%02x>ace<%02x:%02x:%02x:%02x:%02x:%02x>"
3633375       0x3770DF        Neighborly text, "neighbor though no BH info (not even ethernet).ARNING> Fail to update BH info for %02x:%02x:%02x:%02x:%02x:%02x"
3639129       0x378759        Neighborly text, "neighbor[%02x:%02x:%02x:%02x:%02x:%02x] Failed.add neighbor[%d]:%02x:%02x:%02x:%02x:%02x:%02x"
3639196       0x37879C        Neighborly text, "neighbor[%d]:%02x:%02x:%02x:%02x:%02x:%02xap device"
3642009       0x379299        Neighborly text, "neighbor_listil!"
3642159       0x37932F        Neighborly text, "neighbor update event subscribe fail!logy update event subscribe fail!"
3643221       0x379755        Neighborly text, "neighbor of itself.02x] remove neigh[%02x:%02x:%02x:%02x:%02x:%02x]"
3643354       0x3797DA        Neighborly text, "neighbor with [%02x:%02x:%02x:%02x:%02x:%02x]e cookie is NULL"
3643618       0x3798E2        Neighborly text, "neighbor->dev != neigh_devL"
3643793       0x379991        Neighborly text, "neighborx:%02x:%02x:%02x:%02x:%02x   %-10s%-10s"
3659928       0x37D898        Neighborly text, "neighbor[%d] role:%s bandwidth:%d Mbps"
3661186       0x37DD82        Neighborly text, "neighbor[%02x:%02x:%02x:%02x:%02x:%02x] %s %s port[%d]%d). BH <%02x:%02x:%02x:%02x:%02x:%02x--%02x:%02x:%02x:%02x:%02x:%02x> neigh[%02x:%02x:%02x:%02x:%02x:%02x] UNCONFIRMED"
3662011       0x37E0BB        Neighborly text, "Neighbor Updatelist/wlan_sta_list_len"
3684077       0x3836ED        Neighborly text, "Neighbor Request from %02X:%02X:%02X:%02X:%02X:%02X on %signoreFlag to 0."
3684310       0x3837D6        Neighborly text, "NeighborReq ignore.re."
3684463       0x38386F        Neighborly text, "NeighborReq:8 BTMRsp:9 BandHide:10hod Judgement for %02X:%02X:%02X:%02X:%02X:%02X"
3685170       0x383B32        Neighborly text, "Neighbor Request -----02X"
3685315       0x383BC3        Neighborly text, "Neighbor Response -----d"
3685340       0x383BDC        Neighborly text, "neighbor[%d]:%x"
3730151       0x38EAE7        PEM certificate
3730205       0x38EB1D        PEM RSA private key
3763681       0x396DE1        StuffIt Deluxe Segment (data): f
3763927       0x396ED7        StuffIt Deluxe Segment (data): f
3764179       0x396FD3        StuffIt Deluxe Segment (data): fError
3782166       0x39B616        XML document, version: "1.0"
3784068       0x39BD84        AES Inverse S-Box
3785263       0x39C22F        AES S-Box
3787361       0x39CA61        Neighborly text, "neighboretrics"
3788873       0x39D049        Neighborly text, "neighbor_device_device_tlv_all"
3788928       0x39D080        Neighborly text, "neighbor_device_tlv_allghbor_list"
3788988       0x39D0BC        Neighborly text, "neighbor_liste_packet_topology_response"
3791010       0x39D8A2        Neighborly text, "neighbor_backhaul_removeassoc_capability"
3791049       0x39D8C9        Neighborly text, "neighborgent_notify"
3793942       0x39E416        Neighborly text, "neighbor_to_devlookup_eth_sta_by_link_role"
3811928       0x3A2A58        Base64 standard index table
3832804       0x3A7BE4        SHA256 hash constants, little endian
3836596       0x3A8AB4        CRC32 polynomial table, little endian
3847860       0x3AB6B4        SHA256 hash constants, little endian
3875830       0x3B23F6        Copyright string: "Copyright(C) 2019-20"
3889317       0x3B58A5        Neighborly text, "neighbor(%s)X-%02X-%02X] %s%d"
3979539       0x3CB913        AES Inverse S-Box
3980051       0x3CBB13        AES S-Box
3980740       0x3CBDC4        SHA256 hash constants, little endian
4059725       0x3DF24D        Neighborly text, "NeighborReqActioncnReqToAir_SetParam"
4060453       0x3DF525        Neighborly text, "neighbor report framedoes not support beacon report!"
4062114       0x3DFBA2        Neighborly text, "neighbor report response is meaninglessd "
4062314       0x3DFC6A        Neighborly text, "neighbor report frame failed%s, HandleNRReqbyUplayer(%d)!"
4064285       0x3E041D        Neighborly text, "NeighborReqSanityquest LCI Measurement Report"
4064512       0x3E0500        Neighborly text, "NeighborRepme"
4064762       0x3E05FA        Neighborly text, "Neighbor RSP_req_param"
4121110       0x3EE216        Neighborly text, "Neighbor Response Framex:%02x:%02x:%02x"
4229568       0x4089C0        XML document, version: "1.0"
4287776       0x416D20        Unix path: /etc/Wireless/RT2860/RT2860_2G.dat
```

确定入口地址，看了eqqie对于WDR7660的分析，在MyFirmware上方有两个连续出现的相同地址，可能是主程序的加载地址![](https://raw.githubusercontent.com/soskong/Image/main/1773111550416.png)

但是之后加载时出了些问题，然后先直接加载符号表，随便查看一些函数，发现参数是一个很大的十进制数，转成16进制类似于地址![](https://raw.githubusercontent.com/soskong/Image/main/1773111787511.png)

可能是字符串参数的地址，先在且不管这一步进行符号表的提取，随便一个常用的libc函数名

```
i@i-virtual-machine:~/iot/TP-link/TL-WDR7661$ grep -r memcpy .
Binary file ./_TL-WDR7661.bin.extracted/24A5FF matches
```

把24A5FF拿出来分析

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-10%20110927.png)

从0x8开始每8字节一条目

```
1字节flag，Symbol Type，小端模式下，十六进制显示的 54 实际对应的是 Type 0x05（Global Text，代表全局函数），而 74 对应的是 Type 0x07（Global Data，代表全局变量）
3字节偏移量，四字节内存地址
```

第一个条目内存地址为内存地址为0x40205000，即主程序的加载地址0x40205000

#### 修复符号表

将main导入IDA

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-10%20111610.png)

此时函数还是以地址命名，利用改良版的[cha0yang1/VXHUNTER_Fix](https://github.com/cha0yang1/VXHUNTER_Fix?tab=readme-ov-file)进行符号修复（WDR7661使用了精简过的8字节）

安装插件，用插件直接导入包含符号表的24A5FF，插件自动完成分析

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-10%20165803.png)

#### 后

还存在的几个问题

1. IDA中有超出文件边界的使用，内存地址标红，后续的小块LZMA文件数据区没分析，可能对这部分进行访存导致的
2. IDA一些参数无法被识别成字符串，始终以地址显示。有的字符串无法建立引用关系，没办法通过引用跳转，不利于分析

Vxworks方面的知识不太懂，日后学习

#### 参考

[TL-WDR7661 非标准 VxWorks 符号表修复 - IOTsec-Zone](https://www.iotsec-zone.com/article/529)

[PAGalaxyLab/vxhunter: ToolSet for VxWorks Based Embedded Device Analyses](https://github.com/PAGalaxyLab/vxhunter)

[cha0yang1/VXHUNTER_Fix](https://github.com/cha0yang1/VXHUNTER_Fix?tab=readme-ov-file)

[[RTOS] 基于VxWorks的TP-Link路由器固件的通用解压与修复思路 - 赤道企鹅的博客 | Eqqie Blog](https://www.eqqie.cn/index.php/archives/1780/)

[TL-WDR7660 httpProcDataSrv任意代码执行漏洞复现分析_tl-fw防火墙漏洞复现-CSDN博客](https://blog.csdn.net/meichuangkeji/article/details/129884354)

[TP-LINK WDR 7660 固件浅析 - 吾爱破解 - 52pojie.cn](https://www.52pojie.cn/thread-1671088-1-1.html)

[TP-LINK WDR 7660 VxWorks系统分析 – 绿盟科技技术博客](https://blog.nsfocus.net/tp-link-wdr/)
