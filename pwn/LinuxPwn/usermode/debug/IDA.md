| F7        | 单步步进               |
| --------- | ---------------------- |
| F8        | 单步步过               |
| F9        | 继续运行程序           |
| F4        | 运行到光标所在行       |
| Ctrl + F7 | 直到该函数返回时才停止 |
| Ctrl + F2 | 终止一个正在运行的进程 |
| F2        | 设置断点               |

* F7 	单步步进
* F8	单步步过
* F9	继续运行程序
* F4	运行到光标所在行
* Ctrl + F7	直到该函数返回时才停止
* Ctrl + F2	终止一个正在运行的进程
* F2 	设置断点

##### IDA Remote Linux Debugger

将idapro 的 dbgsrv 目录下 的对应的linux_server64复制到linux系统中，并启动服务端：`./linux_server64 -P123456`

ida中选择对应调试器启动即可

#### mipsrop插件

安装好后，每次使用先输入

```
import mipsrop
mipsrop = mipsrop.MIPSROPFinder()
```

执行 `mipsrop.find("")`，寻找rop

##### 参考

[IDA插件 MIPSROP的安装和使用方法_ida插件安装-CSDN博客](https://blog.csdn.net/XiDPPython/article/details/148194489)
