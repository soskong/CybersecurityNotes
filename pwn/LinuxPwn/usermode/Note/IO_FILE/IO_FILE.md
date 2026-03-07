#### 结构体

##### _IO_FILE_plus

```
struct _IO_FILE_plus
{
  _IO_FILE file;
  const struct _IO_jump_t *vtable;
};
```

`_IO_FILE_plus`中包含 `_IO_FILE`结构体和 `_IO_jump_t`指针

vatable指针的偏移量为0xd8

##### _IO_FILE

不同libc版本的_IO_FILE结构体不同，这里给出2.35版本下的，在glibc-2.35\libio\bits\types\struct_FILE.h中被定义

```
struct _IO_FILE
{
  int _flags;		/* High-order word is _IO_MAGIC; rest is flags. */	0

  /* The following pointers correspond to the C++ streambuf protocol. */
  char *_IO_read_ptr;	/* Current read pointer */				0x8
  char *_IO_read_end;	/* End of get area. */					0x10
  char *_IO_read_base;	/* Start of putback+get area. */			0x18
  char *_IO_write_base;	/* Start of put area. */				0x20
  char *_IO_write_ptr;	/* Current put pointer. */				0x28
  char *_IO_write_end;	/* End of put area. */					0x30
  char *_IO_buf_base;	/* Start of reserve area. */				0x38
  char *_IO_buf_end;	/* End of reserve area. */				0x40

  /* The following fields are used to support backing up and undo. */
  char *_IO_save_base; /* Pointer to start of non-current get area. */		0x48
  char *_IO_backup_base;  /* Pointer to first valid character of backup area */	0x50
  char *_IO_save_end; /* Pointer to end of non-current get area. */		0x58

  struct _IO_marker *_markers;							0x60

  struct _IO_FILE *_chain;							0x68

  int _fileno;									0x70
  int _flags2;									0x74
  __off_t _old_offset; /* This used to be _offset but it's too small.  */	0x78

  /* 1+column number of pbase(); 0 is unknown. */
  unsigned short _cur_column;							0x80
  signed char _vtable_offset;
  char _shortbuf[1];

  _IO_lock_t *_lock;								0x88

  __off64_t _offset;								0x90
  /* Wide character stream stuff.  */
  struct _IO_codecvt *_codecvt;							0x98
  struct _IO_wide_data *_wide_data;						0xa0
  struct _IO_FILE *_freeres_list;						0xa8
  void *_freeres_buf;								0xb0
  size_t __pad5;								0xb8
  int _mode;									0xc0

  /* Make sure we don't get into trouble again.  */
  char _unused2[15 * sizeof (int) - 4 * sizeof (void *) - sizeof (size_t)];
};

 const struct _IO_jump_t *vtable;						0xd8
```

* flags：该字段是一个标志位具体的宏如下

  ```
  #define _IO_MAGIC         0xFBAD0000 /* Magic number */
  #define _IO_MAGIC_MASK    0xFFFF0000
  #define _IO_USER_BUF          0x0001 /* Don't deallocate buffer on close. */
  #define _IO_UNBUFFERED        0x0002
  #define _IO_NO_READS          0x0004 /* Reading not allowed.  */
  #define _IO_NO_WRITES         0x0008 /* Writing not allowed.  */
  #define _IO_EOF_SEEN          0x0010
  #define _IO_ERR_SEEN          0x0020
  #define _IO_DELETE_DONT_CLOSE 0x0040 /* Don't call close(_fileno) on close.  */
  #define _IO_LINKED            0x0080 /* In the list of all open files.  */
  #define _IO_IN_BACKUP         0x0100
  #define _IO_LINE_BUF          0x0200
  #define _IO_TIED_PUT_GET      0x0400 /* Put and get pointer move in unison.  */
  #define _IO_CURRENTLY_PUTTING 0x0800
  #define _IO_IS_APPENDING      0x1000
  #define _IO_IS_FILEBUF        0x2000
                             /* 0x4000  No longer used, reserved for compat.  */
  #define _IO_USER_LOCK         0x8000
  ```

  0xFBAD这高四位用作兼容，低16标志位代表特定功能

  在实现任意地址泄露时，通过设置flags为0xfbad1800
* 接下来的8个指针，ptr指向当前读写位置，base为读写基址，end为读写结束地址（最大地址），`_IO_buf_base`和 `_IO_buf_end`表示缓冲区
* _IO_save_base， _IO_backup_base， _IO_save_end三个指针用于备份
* _markers用作文件流的标记，在大文件读写时可以快速恢复，利用时一般设置为0
* _chain指向下一个文件流，偏移为0x68
* _fileno的值就是文件描述符 ，位于 `stdin`文件结构开头 `0x70`偏移处，如：`stdin`的 `fileno`为 `0`，`stdout`的 `fileno`为 `1`，`stderr`的 `fileno`为 `2`，新创建的递增
* __off_t _old_offset用于储存打开文件读写时当前的偏移量
* _cur_column文件流当前列位置
* _vtable_offset
* _codecvt指向用于做编码转换的结构体
* _lock指向锁
* __off64_t _offset表示文件的当前偏移量，在处理大文件时，使用64位的偏移量可以避免溢出问题
* _wide_data指向_IO_wide_data结构体的指针，_IO_wide_data和 `_IO_FILE`结构体类似，也有vtable指针指向_IO_jump_t结构体
* _freeres_list指向释放的文件流
* _freeres_buf指向要被释放的缓冲区，使缓冲区可以被正确释放
* __pad类字段用于结构体对齐
* _mode用于指定文件打开的方式

##### _IO_jump_t

```
struct _IO_jump_t
{
    JUMP_FIELD(size_t, __dummy);			0x0
    JUMP_FIELD(size_t, __dummy2);			0x8
    JUMP_FIELD(_IO_finish_t, __finish);			0x10
    JUMP_FIELD(_IO_overflow_t, __overflow);		0x18
    JUMP_FIELD(_IO_underflow_t, __underflow);		0x20
    JUMP_FIELD(_IO_underflow_t, __uflow);		0x28
    JUMP_FIELD(_IO_pbackfail_t, __pbackfail);		0x30
    /* showmany */
    JUMP_FIELD(_IO_xsputn_t, __xsputn);			0x38
    JUMP_FIELD(_IO_xsgetn_t, __xsgetn);			0x40
    JUMP_FIELD(_IO_seekoff_t, __seekoff);		0x48
    JUMP_FIELD(_IO_seekpos_t, __seekpos);		0x50
    JUMP_FIELD(_IO_setbuf_t, __setbuf);			0x58
    JUMP_FIELD(_IO_sync_t, __sync);			0x60
    JUMP_FIELD(_IO_doallocate_t, __doallocate);		0x68
    JUMP_FIELD(_IO_read_t, __read);			0x70
    JUMP_FIELD(_IO_write_t, __write);			0x78
    JUMP_FIELD(_IO_seek_t, __seek);
    JUMP_FIELD(_IO_close_t, __close);
    JUMP_FIELD(_IO_stat_t, __stat);
    JUMP_FIELD(_IO_showmanyc_t, __showmanyc);
    JUMP_FIELD(_IO_imbue_t, __imbue);
};
```

宏 `#define JUMP_FIELD(TYPE, NAME) TYPE NAME`

* __dummy用于对齐
* __finish文件关闭时的操作
* __overflow在缓冲区已满时执行的操作
* __underflow在文件操作中处理数据的读取操作
* __uflow函数的主要作用是从输入流中提取当前元素，并将其推进到下一个位置，实现通常调用 `underflow()` 函数
* __pbackfail用于重新获取字符
* __xsputn用于批量写入字符的高效操作
* __xsputn用于批量读取字符的高效操作
* __seekoff，__seekpos用于改变文件流当前指针位置
* __setbuf用于设置缓冲区
* __sync用于多线程原子操作
* __doallocate用于分配内存
* __read 和__write用于读写操作
* __seek用于定位文件指针
* __close文件关闭操作
* __stat用于获取文件状态
* __showmanyc用于检查缓冲区中是否有可读取的字符，它的功能是返回缓冲区中可以读取的字符数量
* __imbue用于执行特定操作

##### _IO_wide_data

```
struct _IO_wide_data
{
  wchar_t *_IO_read_ptr;	/* Current read pointer */
  wchar_t *_IO_read_end;	/* End of get area. */
  wchar_t *_IO_read_base;	/* Start of putback+get area. */
  wchar_t *_IO_write_base;	/* Start of put area. */
  wchar_t *_IO_write_ptr;	/* Current put pointer. */
  wchar_t *_IO_write_end;	/* End of put area. */
  wchar_t *_IO_buf_base;	/* Start of reserve area. */
  wchar_t *_IO_buf_end;		/* End of reserve area. */
  /* The following fields are used to support backing up and undo. */
  wchar_t *_IO_save_base;	/* Pointer to start of non-current get area. */
  wchar_t *_IO_backup_base;	/* Pointer to first valid character of
				   backup area */
  wchar_t *_IO_save_end;	/* Pointer to end of non-current get area. */		0x58

  __mbstate_t _IO_state;								0x60
  __mbstate_t _IO_last_state;								0x68
  struct _IO_codecvt _codecvt;

  wchar_t _shortbuf[1];

  const struct _IO_jump_t *_wide_vtable;						0xe0
};
```

##### 概述

初始时会创建三个 `_IO_FILE_plus`结构体分别为 `_IO_2_1_stdin_`，`_IO_2_1_stdout_`，`_IO_2_1_stderr_`，它们分布在libc的可写数据段，而之后打开新的文件流，会在堆上创建 `_IO_FILE_plus`结构体	,指向顺序为 `_IO_list_all`-> `_IO_2_1_stderr_ `-> `_IO_2_1_stdout_ `-> `_IO_2_1_stdin_`，新的文件对象从链表头部插入

`_IO_list_all`是一个全局的 `_IO_FILE_plus`指针，用来维护创建的 `_IO_FILE_plus`结构体，默认指向链表头部文件对象

`_IO_file_jumps`是 `_IO_jump_t`结构体，所有的 `_IO_FILE_plus`的vtable指针都指向 `_IO_file_jumps`，位于libc的不可写的数据段上

#### stdout任意地址内容泄露

利用puts函数执行时

```
int _IO_puts (const char *str)
{
    int result = EOF;
    size_t len = strlen (str);
     _IO_acquire_lock (stdout);

    if ((_IO_vtable_offset (stdout) != 0 || _IO_fwide (stdout, -1) == -1) && _IO_sputn (stdout, str, len) == len && _IO_putc_unlocked ('\n', stdout) != EOF)
        result = MIN (INT_MAX, len + 1);

    _IO_release_lock (stdout);
    return result;
}
```

会调用_IO_sputn函数，实际上调用了stdout的_xsputn字段，即_IO_file_xsputn，即_IO_new_file_xsputn

```
size_t _IO_new_file_xsputn (FILE *f, const void *data, size_t n)
{
  const char *s = (const char *) data;
  size_t to_do = n;
  int must_flush = 0;
  size_t count = 0;

  if (n <= 0)
    return 0;
  /* This is an optimized implementation.
     If the amount to be written straddles a block boundary
     (or the filebuf is unbuffered), use sys_write directly. */

  /* First figure out how much space is available in the buffer. */
  if ((f->_flags & _IO_LINE_BUF) && (f->_flags & _IO_CURRENTLY_PUTTING))
    {
	...
    }
  else if (f->_IO_write_end > f->_IO_write_ptr)
    count = f->_IO_write_end - f->_IO_write_ptr; /* Space available. */

  /* Then fill the buffer. */
  if (count > 0)
    {
	...
    }
  if (to_do + must_flush > 0)
    {
      size_t block_size, do_write;
      /* Next flush the (full) buffer. */
      if (_IO_OVERFLOW (f, EOF) == EOF)
	...
  return n - to_do;
}
```

调用到了stdout的_IO_OVERFLOW，即_IO_new_file_overflow

```
int _IO_new_file_overflow (FILE *f, int ch)
{
	 ...
  	 if ((f->_flags & _IO_UNBUFFERED) || ((f->_flags & _IO_LINE_BUF) && ch == '\n'))
    		 if (_IO_do_write (f, f->_IO_write_base, f->_IO_write_ptr - f->_IO_write_base) == EOF)
      			 return EOF;
  	 return (unsigned char) ch;
}
```

调用了_IO_do_write，即_IO_new_do_write

```
int _IO_new_do_write (FILE *fp, const char *data, size_t to_do)
{
	return (to_do == 0 || (size_t) new_do_write (fp, data, to_do) == to_do) ? 0 : EOF;
}
```

调用了new_do_write

```
static size_t new_do_write (FILE *fp, const char *data, size_t to_do)
{
  size_t count;
  if (fp->_flags & _IO_IS_APPENDING)
    /* On a system without a proper O_APPEND implementation,
       you would need to sys_seek(0, SEEK_END) here, but is
       not needed nor desirable for Unix- or Posix-like systems.
       Instead, just indicate that offset (before and after) is
       unpredictable. */
    fp->_offset = _IO_pos_BAD;
  else if (fp->_IO_read_end != fp->_IO_write_base)
    {
      off64_t new_pos
	= _IO_SYSSEEK (fp, fp->_IO_write_base - fp->_IO_read_end, 1);
      if (new_pos == _IO_pos_BAD)
	return 0;
      fp->_offset = new_pos;
    }
  count = _IO_SYSWRITE (fp, data, to_do);
  ...
}
```

_IO_SYSWRITE宏

`#define _IO_SYSWRITE(FP, DATA, LEN) JUMP2 (__write, FP, DATA, LEN)`

调用了stdout的_write函数，最后其实就是使用write进行了一个输出

如果修改stdout的各个字段，最后能实现输出_IO_write_base到_IO_write_ptr的内容，通过将flag伪造为0xfbad1800来进入正确利用分支
