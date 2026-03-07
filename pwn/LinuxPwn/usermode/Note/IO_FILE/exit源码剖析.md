### 流程

```
exit -> __run_exit_handlers -> __call_tls_dtors 析构TLS变量 
                            -> 析构 listp ,循环调用注册的函数，调用_dl_fini函数
			    -> _IO_cleanup -> _IO_flush_all_lockp -> 调用对应fd的_IO_overflow函数
					      _IO_unbuffer_all -> 调用对应函数的 setbuf函数
			    -> __exit 
```

### exit

```
void exit (int status)
{
  __run_exit_handlers (status, &__exit_funcs, true, true);
}
```

### __run_exit_handlers

__run_exit_handlers是主要实现所在，包括三个阶段

```
void attribute_hidden __run_exit_handlers (int status, struct exit_function_list **listp, bool run_list_atexit, bool run_dtors)
{
  /* First, call the TLS destructors.  */
#ifndef SHARED
  if (&__call_tls_dtors != NULL)
#endif
    if (run_dtors)
      __call_tls_dtors ();

  __libc_lock_lock (__exit_funcs_lock);

  /* We do it this way to handle recursive calls to exit () made by
     the functions registered with `atexit' and `on_exit'. We call
     everyone on the list and use the status value in the last
     exit (). */
  while (true)
    {
      struct exit_function_list *cur = *listp;

      if (cur == NULL)
	{
	  /* Exit processing complete.  We will not allow any more
	     atexit/on_exit registrations.  */
	  __exit_funcs_done = true;
	  break;
	}

      while (cur->idx > 0)
	{
	  struct exit_function *const f = &cur->fns[--cur->idx];
	  const uint64_t new_exitfn_called = __new_exitfn_called;

	  switch (f->flavor)
	    {
	      void (*atfct) (void);
	      void (*onfct) (int status, void *arg);
	      void (*cxafct) (void *arg, int status);
	      void *arg;

	    case ef_free:
	    case ef_us:
	      break;
	    case ef_on:
	      onfct = f->func.on.fn;
	      arg = f->func.on.arg;
#ifdef PTR_DEMANGLE
	      PTR_DEMANGLE (onfct);
#endif
	      /* Unlock the list while we call a foreign function.  */
	      __libc_lock_unlock (__exit_funcs_lock);
	      onfct (status, arg);
	      __libc_lock_lock (__exit_funcs_lock);
	      break;
	    case ef_at:
	      atfct = f->func.at;
#ifdef PTR_DEMANGLE
	      PTR_DEMANGLE (atfct);
#endif
	      /* Unlock the list while we call a foreign function.  */
	      __libc_lock_unlock (__exit_funcs_lock);
	      atfct ();
	      __libc_lock_lock (__exit_funcs_lock);
	      break;
	    case ef_cxa:
	      /* To avoid dlclose/exit race calling cxafct twice (BZ 22180),
		 we must mark this function as ef_free.  */
	      f->flavor = ef_free;
	      cxafct = f->func.cxa.fn;
	      arg = f->func.cxa.arg;
#ifdef PTR_DEMANGLE
	      PTR_DEMANGLE (cxafct);
#endif
	      /* Unlock the list while we call a foreign function.  */
	      __libc_lock_unlock (__exit_funcs_lock);
	      cxafct (arg, status);
	      __libc_lock_lock (__exit_funcs_lock);
	      break;
	    }

	  if (__glibc_unlikely (new_exitfn_called != __new_exitfn_called))
	    /* The last exit function, or another thread, has registered
	       more exit functions.  Start the loop over.  */
            continue;
	}

      *listp = cur->next;
      if (*listp != NULL)
	/* Don't free the last element in the chain, this is the statically
	   allocate element.  */
	free (cur);
    }

  __libc_lock_unlock (__exit_funcs_lock);

  if (run_list_atexit)
    RUN_HOOK (__libc_atexit, ());

  _exit (status);
}
```

#### 第一阶段

调用TLS的析构函数__call_tls_dtors，这个析构函数负责析构 `thread_local`中声明的TLS变量

```
void __call_tls_dtors (void)
{
  while (tls_dtor_list)
    {
      struct dtor_list *cur = tls_dtor_list;
      dtor_func func = cur->func;
#ifdef PTR_DEMANGLE
      PTR_DEMANGLE (func);
#endif

      tls_dtor_list = tls_dtor_list->next;
      func (cur->obj);

      /* Ensure that the MAP dereference happens before
	 l_tls_dtor_count decrement.  That way, we protect this access from a
	 potential DSO unload in _dl_close_worker, which happens when
	 l_tls_dtor_count is 0.  See CONCURRENCY NOTES for more detail.  */
      atomic_fetch_add_release (&cur->map->l_tls_dtor_count, -1);
      free (cur);
    }
}
```

#### 第二阶段

循环处理使用“atexit”和“on_exit”注册的函数

一开始的函数调用 `__run_exit_handlers (status, &__exit_funcs, true, true);`

第二个参数是__exit_funcs实际上是一个exit_function_list的指针，指向了initial（exit_function_list结构体）

exit_function_list结构体

```
struct exit_function_list
{
    struct exit_function_list *next;
    size_t idx;
    struct exit_function fns[32];
};
```

exit_function结构体

```
struct exit_function
  {
    /* `flavour' should be of type of the `enum' above but since we need
       this element in an atomic operation we have to use `long int'.  */
    long int flavor;
    union
      {
	void (*at) (void);
	struct
	  {
	    void (*fn) (int status, void *arg);
	    void *arg;
	  } on;
	struct
	  {
	    void (*fn) (void *arg, int status);
	    void *arg;
	    void *dso_handle;
	  } cxa;
      } func;
  };
```

而 `struct exit_function_list *cur = *listp;`，这个listp就是initial

这部分关键代码如下

```
    while (true)
    {
		// 遍历exit_function_list
		struct exit_function_list *cur = *listp;

		if (cur == NULL)
		{
		/* Exit processing complete.  We will not allow any more
		atexit/on_exit registrations.  */
		__exit_funcs_done = true;
		break;
		}

		// 遍历exit_function并调用内部的函数指针
		while (cur->idx > 0)
		{
			struct exit_function *const f = &cur->fns[--cur->idx];
			const uint64_t new_exitfn_called = __new_exitfn_called;

			switch (f->flavor)
			{
				// 函数调用
			}

			if (__glibc_unlikely (new_exitfn_called != __new_exitfn_called))
			/* The last exit function, or another thread, has registered
	        	more exit functions.  Start the loop over.  */
				continue;
		}
		// 指向exit_function_list的
		*listp = cur->next;
		if (*listp != NULL)
			free (cur);
    }
```

遍历exit_function_list链表的过程中，会固定执行_dl_fini函数，这部分的利用之后细说

#### 第三阶段

`RUN_HOOK (__libc_atexit, ());`，经过一系列宏的展开 `__libc_atexit`，实际上最终调用的是_IO_cleanup函数

```
int _IO_cleanup (void)
{
  int result = _IO_flush_all_lockp (0);
  _IO_unbuffer_all ();
  return result;
}

```

##### _IO_flush_all_lockp

```
int _IO_flush_all_lockp (int do_lock)
{
    int result = 0;
    FILE *fp;

#ifdef _IO_MTSAFE_IO
    _IO_cleanup_region_start_noarg (flush_cleanup);
    _IO_lock_lock (list_all_lock);
#endif

    for (fp = (FILE *) _IO_list_all; fp != NULL; fp = fp->_chain)
    {
         run_fp = fp;
        if (do_lock)
	        _IO_flockfile (fp);

        if (((fp->_mode <= 0 && fp->_IO_write_ptr > fp->_IO_write_base) || (_IO_vtable_offset (fp) == 0 && fp->_mode > 0 && (fp->_wide_data->_IO_write_ptr > fp->_wide_data->_IO_write_base))) && _IO_OVERFLOW (fp, EOF) == EOF)
	        result = EOF;

        if (do_lock)
	        _IO_funlockfile (fp);
        run_fp = NULL;
    }

#ifdef _IO_MTSAFE_IO
    _IO_lock_unlock (list_all_lock);
    _IO_cleanup_region_end (0);
#endif

  return result;
}
```

在这部分的if判断中会调用文件对象对应的_IO_OVERFLOW函数

##### _IO_unbuffer_all

```
static void _IO_unbuffer_all (void)
{
    FILE *fp;

#ifdef _IO_MTSAFE_IO
    _IO_cleanup_region_start_noarg (flush_cleanup);
    _IO_lock_lock (list_all_lock);
#endif

    for (fp = (FILE *) _IO_list_all; fp; fp = fp->_chain)
    {
        int legacy = 0;

#if SHLIB_COMPAT (libc, GLIBC_2_0, GLIBC_2_1)
        if (__glibc_unlikely (_IO_vtable_offset (fp) != 0))
	        legacy = 1;
#endif

        if (! (fp->_flags & _IO_UNBUFFERED) && (legacy || fp->_mode != 0))
	    {
#ifdef _IO_MTSAFE_IO
	        int cnt;
#define MAXTRIES 2
	        for (cnt = 0; cnt < MAXTRIES; ++cnt)
	            if (fp->_lock == NULL || _IO_lock_trylock (*fp->_lock) == 0)
	                break;
	            else
	                __sched_yield ();
#endif

	        if (! legacy && ! dealloc_buffers && !(fp->_flags & _IO_USER_BUF))
	        {
	            fp->_flags |= _IO_USER_BUF;

	            fp->_freeres_list = freeres_list;
	            freeres_list = fp;
	            fp->_freeres_buf = fp->_IO_buf_base;
	        }

	        _IO_SETBUF (fp, NULL, 0);

	        if (! legacy && fp->_mode > 0)
	            _IO_wsetb (fp, NULL, NULL, 0);

#ifdef _IO_MTSAFE_IO
	        if (cnt < MAXTRIES && fp->_lock != NULL)
	            _IO_lock_unlock (*fp->_lock);
#endif
	    }

        /* Make sure that never again the wide char functions can be
	    used.  */
        if (! legacy)
	        fp->_mode = -1;
    }

#ifdef _IO_MTSAFE_IO
    _IO_lock_unlock (list_all_lock);
    _IO_cleanup_region_end (0);
#endif
}
```

会循环调用 `_IO_SETBUF (fp, NULL, 0);`调用文件对象的setbuf函数

#### 第四阶段

由__exit -> abort终止进程

### 总结

利用

1. 劫持 `tls_dtor_list`指针
2. 劫持 `exit_function_list`的函数指针
3. 对 `_dl_fini` 的利用
4. 劫持文件vtable的IO_overflow
5. 劫持文件vtable的setbuf

### 利用

#### IO_overflow

注意到会调用 `_IO_OVERFLOW (fp, EOF)`

```
#define _IO_OVERFLOW(FP, CH) JUMP1 (__overflow, FP, CH)
```

即 `JUMP1 (__overflow,fp,EOF)`

```
#define JUMP1(FUNC, THIS, X1) (_IO_JUMPS_FUNC(THIS)->FUNC) (THIS, X1)
```

即 `(_IO_JUMPS_FUNC(fp)->__overflow) (fp, EOF)`

```
# define _IO_JUMPS_FUNC(THIS)  (IO_validate_vtable (*(struct _IO_jump_t **) ((void *) &_IO_JUMPS_FILE_plus (THIS) + (THIS)->_vtable_offset)))
```

总之就是先对vtable做了一个检查，如果成功就返回vatble，失败abort

...
