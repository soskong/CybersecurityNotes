#### AFL原理

[AFL 漏洞挖掘技术漫谈（一）：用 AFL 开始你的第一次 Fuzzing (seebug.org)](https://paper.seebug.org/841/#_2)

#### 安装

1. 获取源码[google/AFL: american fuzzy lop - a security-oriented fuzzer (github.com)](https://github.com/google/AFL)，[AFLplusplus/AFLplusplus: The fuzzer afl++ is afl with community patches, qemu 5.1 upgrade, collision-free coverage, enhanced laf-intel &amp; redqueen, AFLfast++ power schedules, MOpt mutators, unicorn_mode, and a lot more! (github.com)](https://github.com/AFLplusplus/AFLplusplus)

   推荐使用afl++
2. 编译

   ```
   make 
   sudo make install
   ```

   目录下生成了afl-gcc，afl-fuzz即表明编译成功
3. 启用qemu进行无源码fuzz

   ```
   cd qemu_mode
   ./build_qemu_support.sh
   cd ..
   sudo make install
   ```

##### 修正

之后在对arm固件fuzz时，遇到了qemu架构没有被编译的问题，完整安装流程如下

```
sudo apt install -y cmake build-essential libtool pkg-config libglib2.0-dev libpixman-1-dev	# cmake
git clone https://github.com/AFLplusplus/AFLplusplus && cd AFLplusplus
cd AFLplusplus
make distrib		# make distrib 是 AFL++ 用于编译全量分发版的指令，会自动编译包括 Unicorn 模式在内的所有组件

sudo make install
cd ./AFLplusplus/qemu_mode/
export CPU_TARGET=arm
./build_qemu_support.sh

cd ..
make clean
make
sudo make install
```

[[原创]用AFL++对ARM固件进行模糊测试-二进制漏洞-看雪安全社区｜专业技术交流与安全研究论坛](https://bbs.kanxue.com/thread-267074.htm)

##### 有源码下的fuzz

1. 使用afl-gcc对目标进行编译 `afl-gcc ./vuln.c -o vuln`
2. 创建一个语料库作为初始输入
3. 执行 `afl-fuzz vuln -i ../in -o ../output`，测试结果默认保存在 `../output/default`下，会覆盖

```
            american fuzzy lop ++4.22a {default} (./vuln) [explore]      
┌─ process timing ────────────────────────────────────┬─ overall results ────┐
│        run time : 0 days, 0 hrs, 0 min, 58 sec      │  cycles done : 33    │
│   last new find : 0 days, 0 hrs, 0 min, 56 sec      │ corpus count : 9     │
│last saved crash : 0 days, 0 hrs, 0 min, 10 sec      │saved crashes : 5     │
│ last saved hang : none seen yet                     │  saved hangs : 0     │
├─ cycle progress ─────────────────────┬─ map coverage┴──────────────────────┤
│  now processing : 8.33 (88.9%)       │    map density : 0.05% / 0.08%      │
│  runs timed out : 0 (0.00%)          │ count coverage : 1.00 bits/tuple    │
├─ stage progress ─────────────────────┼─ findings in depth ─────────────────┤
│  now trying : havoc                  │ favored items : 9 (100.00%)         │
│ stage execs : 282/400 (70.50%)       │  new edges on : 9 (100.00%)         │
│ total execs : 105k                   │ total crashes : 855 (5 saved)       │
│  exec speed : 1814/sec               │  total tmouts : 0 (0 saved)         │
├─ fuzzing strategy yields ────────────┴─────────────┬─ item geometry ───────┤
│   bit flips : 0/0, 0/0, 0/0                        │    levels : 7         │
│  byte flips : 0/0, 0/0, 0/0                        │   pending : 0         │
│ arithmetics : 0/0, 0/0, 0/0                        │  pend fav : 0         │
│  known ints : 0/0, 0/0, 0/0                        │ own finds : 8         │
│  dictionary : 0/0, 0/0, 0/0, 0/0                   │  imported : 0         │
│havoc/splice : 13/105k, 0/0                         │ stability : 100.00%   │
│py/custom/rq : unused, unused, unused, unused       ├───────────────────────┘
│    trim/eff : 37.50%/13, n/a                       │          [cpu000: 25%]
└─ strategy: explore ────────── state: started :-) ──┘^C
```

##### 无源码下的qemu mode

编译时不采用 `afl-fcc`编译，任意的二进制文件

测试时对目标使用 `-Q`参数 `afl-fuzz -i ../in/ -o ../output/ -Q ./vuln`
