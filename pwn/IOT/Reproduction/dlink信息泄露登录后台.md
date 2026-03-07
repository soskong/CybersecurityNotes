#### 解包

#### 模拟固件

启动命令为

```
REQUEST_METHOD=GET qemu-mipsel -L . ./phpcgi aaaaaaaaa bbbbbbbbbbb ccccccc dddddddd
```

#### 分析

存在漏洞的文件是 `/htdocs/web/getcfg.php`：

![img](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-06%20160841.png)

如果实现

```
CACHE = False
$AUTHORIZED_GROUP >= 0
```

就可以执行 `/htdocs/webinc/getcfg/".$GETCFG_SVC.".xml.php` 文件

查找 `/htdocs/webinc/getcfg/` 目录下的文件，执行 `DEVICE.ACCOUNT.xml.php` 可泄露后台账号密码

![](https://raw.githubusercontent.com/soskong/Image/main/Screenshot%202026-03-06%20171521.png)

绕过

cache应该是表示有无用户登录，实际上只要考虑 `$AUTHORIZED_GROUP >= 0` 即可

在php代码文件中找不到 `$AUTHORIZED_GROUP` 的定义，说明其可能通过二进制文件解析的url
