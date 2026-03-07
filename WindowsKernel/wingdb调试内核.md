#### 常用命令

列出全部进程信息：`!process 0 0`

```
...
PROCESS ffffde846089d080
    SessionId: 0  Cid: 04f8    Peb: 95daa8d000  ParentCid: 0338
    DirBase: 1128b7000  ObjectTable: ffff8a0be7cb25c0  HandleCount: 119.
    Image: svchost.exe
...
```

* `PROCESS`：这是进程控制块的内存地址。每个进程都有一个唯一的内存地址来存储其信息。
* `SessionId`: 会话 ID，表示该进程所属的会话。对于服务或系统进程，通常是 0。
* `Cid` : 客户端 ID，或进程 ID (PID)，用于唯一标识进程。
* `b` : 进程环境块 (PEB) 的地址，包含进程的环境变量、启动参数等信息。
* `ParentCid`: 父进程的 ID，表示哪个进程启动了当前进程。
* `DirBase` : 页目录基地址，用于内存管理和地址转换。
* `ObjectTable` : 进程的对象表地址，其中包含该进程打开的所有句柄。
* `HandleCount` : 该进程当前打开的句柄数量。
* `Image` : 进程的映像名称，即可执行文件名。

显示数据结构的布局和内容

查看结构体：`dt <struct_name>`

查看结构体数据：`dt <struct_name> <struct_addr>`

查看特定字段的值：`dt <struct_name> <struct_addr> <FieldName>`

* **-r** : 递归显示嵌套结构。
* **-b** : 显示结构体的基类。
* **-v** : 显示结构体的详细信息。

##### 断点

* 在地址处下断点： `bp [Address]`
* 针对于内存数据访问下断点： `ba  [Access  Size]  [address]`。Access 是访问的方式（erw）。Size 是监控访问的位置的大小，以字节为单位。比如要对内存0x0483DFE进行写操作的时候下断点，可以用命令 ` ba w4 0x0483DFE`
* 列出所有断点：`bl`
* 清除断点：`bc`
* 禁用断点：`bd`
* 启动被bd命令禁用的断点：`be`
