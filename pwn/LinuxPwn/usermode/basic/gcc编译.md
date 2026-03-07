#### gcc编译

1. 预处理：`gcc -E hello.c -o hello.i`
   预处理器执行宏替换、条件编译以及包含指定的文件，生成预处理后文件
2. 编译：`gcc -S hello.i -o hello.s `
   生成汇编源代码文件
3. 汇编：`gcc -c hello.s -o hello.o`
   生成可重定位目标文件，机器码文件，不可直接执行
4. 链接：`gcc -O hello.o -o hello`
   合并所有文件的各个 section，调整段的大小及段的起始位置。合并符号表，进行符号解析，并给符号分配一个虚拟地址。
   进行符号重定位，在使用符号的地方，全部替换成符号的虚拟地址

#### Protection

1. RELRO（ReLocation Read-Only）：分两种情况

   * Partial RELRO：got表可写
   * Full RELRO：got表只读不可写

   gcc默认开启

   ```
   -z norelro // 关闭
   -z lazy // 部分开启
   -z now // 全部开启
   ```
2. Canary：在栈帧中插入一个随机数，在函数执行完返回之前检查随机数是否被修改来判断栈是否溢出，金丝雀，堆栈溢出哨兵，栈保护技术
   gcc默认不开启

   ```
   -fno-stack-protector // 禁用
   -fstack-protector // 开启
   -fstack-protector-all // 完全开启
   ```
3. NX（no execute）：栈上的数据不可以当作代码执行，堆栈禁止执行
   gcc默认开启

   ```
   -z execstack // 禁用NX保护
   -z noexecstack // 开启NX保护
   ```
4. PIE（Position Independent Executable）：地址无关可执行文件，也称ASLR(Address Space Layout Randomization)，地址空间布局随机化，随机放置进程关键数据区域的地址空间来防止攻击者能可靠地跳转到内存的特定位置来利用函数
   gcc默认开启

   ```
   -no-pie    // 关闭PIE，0
   -fpie -pie // 开启PIE，此时强度为1：半随机 code&data、stack、mmap、vdso随机化
   -fPIE -pie // 开启PIE，此时为最高强度2：全随机 在1的基础上加上heap随机化
   ```
5. FORTIFY：轻微的检查，用于检查是否存在缓冲区溢出的错误
   gcc默认不开启

   ```
   -D_FORTIFY_SOURCE=1	// 较弱的检查
   -D_FORTIFY_SOURCE=2	// 较强的检查
   ```
6. RPATH/RUNPATH

   可以在编译时指定程序运行时动态链接库的搜寻路径，防止一些动态库被恶意替换

   ```
   gcc –Wl,-rpath              // 指定运行时动态链接库的搜寻路径，硬编码进ELF文件 “RPATH”选项。
   LD_RUN_PATH 环境变量         // 指定运行时动态链接库的搜寻路径，硬编码进ELF文件 “RPATH”选项。

   -Wl,--disable-new-dtags     // 表明使用 RPATH 
   -Wl,--enable-new-dtags      // 标示使用 RUNPATH 
   ```

### 其他参数

#### 优化

##### Red zone

被调用的函数不扩展新栈，直接使用rbp（rsp）上方的128字节传递参数使用

| 选项                        | 禁用内容               |
| --------------------------- | ---------------------- |
| `-fno-omit-frame-pointer` | 强制 rbp 作为栈基址    |
| `-mno-red-zone`           | 禁止使用 rsp 下方 128B |
