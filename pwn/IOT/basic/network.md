#### ifupdown

##### 配置文件

```
auto lo				指定了接口lo在启动时应该自动配置
iface lo inet loopback		为lo配置回环地址

auto eth0			指定了接口eth0在启动时应该自动配置
iface eth0 inet dhcp		dhcp配置ip
up ifconfig eth0 0.0.0.0 up	在启动后，清空ip

auto br0			指定了接口br0在启动时应该自动配置
iface br0 inet dhcp		dhcp配置ip

bridge_ports eth0		把 eth0 作为一个端口（port），接入 br0 这个 bridge
bridge_maxwait 0		延迟设为0，不等待
```

以上配置完成后，流量流向为

```
外部交换机 -- eth0（L2）-- br0（L3）-- IP协议栈
```

eth0属于br0的一个隶属的接口

https://my.oschina.net/emacs_8857537/blog/17438692

##### hook

| hook 关键字   | 触发时机         |
| ------------- | ---------------- |
| `pre-up`    | 接口 up 之前     |
| `up`        | 接口 up 之后     |
| `down`      | 接口 down 时     |
| `post-down` | 接口彻底 down 后 |

在触发时机完成后执行配置命令 `[hook_key] [command]`

#### NetworkManager

##### 桥接配置

达到如上配置文件的效果

```
删掉ens33连接，防止ens33被当成 L3 口，DHCP 抢 IP
nmcli connection delete "Wired connection 1"

创建 bridge（br0），并启用 DHCP
nmcli connection add type bridge \
  ifname br0 \
  con-name br0 \
  ipv4.method auto \
  ipv6.method ignore

把 ens33 加入 bridge
nmcli connection add type ethernet \
  ifname ens33 \
  con-name br0-slave-ens33 \
  master br0

启动连接
nmcli connection up br0
nmcli connection up br0-slave-ens33 
```

##### 常用命令

```
查看类
nmcli device status        # 看网卡和绑定的 connection
nmcli connection show     # 看所有 profile
nmcli connection show --active

启停连接
nmcli connection up <conn>
nmcli connection down <conn>

创建连接
普通以太网：nmcli connection add type ethernet ifname ens33 con-name ens33-dhcp
Bridge：nmcli connection add type bridge ifname br0 con-name br0 ipv4.method auto
Bridge Slave：nmcli connection add type ethernet ifname ens33 con-name br0-slave-ens33 master br0

删除
nmcli connection delete <conn>
```

#### ip

`ip` 命令是 iproute2 工具集的核心，本质是 直接和 Linux 内核 netlink 套接字通信 ，走的是  kernel 原生网络栈。

手动创建桥

```
sudo ip link add name br0 type bridge
sudo ip link set br0 up
```

把 ens33 桥接到br0

```
sudo ip addr flush dev ens33
sudo ip linkset ens33 master br0
```
