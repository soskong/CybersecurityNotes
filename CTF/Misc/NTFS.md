#### 交换数据流

NTFS交换数据流（alternate data streams，简称ADS）是NTFS磁盘格式的一个特性，在NTFS文件系统下，每个文件都可以存在多个数据流，就是说除了主文件流之外还可以有许多非主文件流寄宿在主文件流中。它使用资源派生来维持与文件相关的信息，虽然我们无法看到数据流文件，但是它却是真实存在于我们的系统中的。创建一个数据交换流文件的方法很简单，命令为"宿主文件:准备与宿主文件关联的数据流文件"。

#### 隐藏文件

```
echo aaa > a.txt	创建宿主文件
echo bbb > a.txt:b.txt 	创建交换数据流文件
```

此时在Explorer GUI界面下 `b.txt`不可见，可以通过notepad打开a.txt:b.txt（加上绝对路径）查看文件内容

此外，还可以通过type命令达到隐藏图片或可执行文件

运行可执行文件，在xp系统之前使用start加交换数据流文件绝对路径可以执行，win7之后被禁止，需要通过创建一个链接来运行

```
type test.exe > a.txt:test.exe			
mklink fake.exe C:\Users\Lenovo\a.txt:test.exe
```

但是在执行时虚拟机上的360报毒，对这种类型的隐藏av有检测
