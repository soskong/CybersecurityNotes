#### Google

##### 运算符

* 逻辑与：and
* 逻辑或： or
* 逻辑非： -
* 完整匹配："关键词"
* 通配符：* ?

##### 高级搜索

intext：寻找正文中含有关键字的网页

intitle：寻找标题中含有关键字的网页

allintitle：用法和intitle类似，只不过可以指定多个词，多个关键词用空格区分

inurl：将返回url中含有关键词的网页

allinurl：可以指定多个关键词

site：只显示指定的站点

filetype：指定访问的文件类型

related：返回类似的网页类型，前端结构相似

info：返回站点的指定信息


使用案例：

例如Oyst3r想测一个学校的内部系统漏洞，但是他没有这个系统的账号密码，生蚝跟据google hack大法，使用了如下语句

先获取带有学号与姓名的敏感文件：`filetype:pdf and site:tyut.edu.cn and intext:学号` 

    `filetype:pdf site:tyut.edu.cn and intext:身份证号`

再获取某个平台的初始密码/默认密码相关信息：`filetype:pdf and site:tyut.edu.cn and intext:初始密码`

由此得到的信息登入内部系统进行渗透测试

#### Fofa

常用语法：

ip或c段：`ip = "192.168.1.1"` `ip = "192.168.1.0/24"`

标题：`title="titlename"`

http头部：`header="elastic"`

html正文包含内容：`body="网络空间测绘"`

指定根域名：`domain="qq.com"`

网站图标hash值：`icon_hash="-1140588745"`
