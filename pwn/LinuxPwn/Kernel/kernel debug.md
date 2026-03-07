#### gdb

1. 配置参数，qemu启动脚本

   1. -s或-gdb tcp::1234
   2. 关闭kaslr
   3. 以root权限启动
2. gdb监听1234端口前先加载符号文件

   ```
   gdb -q 安静模式启动
   	-ex "file vmlinux"	加载 vmlinux 的 ELF + 符号表到 GDB
   	-ex "add-symbol-file ko_test.ko 0xffffffffc0000000"
   	与 vmlinux 不同，使用 add-symbol-file 加载内核模块符号时，必须指定内核模块的 text 段基地址。
   	-ex "target remote localhost:1234"   
   ```

   获取模块的加载基质可以：

   ```
   # method 1
   grep target_module_name /proc/modules 
   # method 2
   cat /sys/module/ko_test/sections/.text 
   # method 3
   lsmod
   ```
