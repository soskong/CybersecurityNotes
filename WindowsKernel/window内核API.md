#### psLookupProcessByProcessId

```
NTSTATUS PsLookupProcessByProcessId(
  [in]  HANDLE    ProcessId,
  [out] PEPROCESS *Process
);
```

* `[in] ProcessId`指定进程的进程 ID。
* `[out] Process`返回指向 *ProcessId* 指定的进程的 EPROCESS 结构的引用指针。

#### MmCopyVirtualMemory

`MmCopyVirtualMemory(Global_Peprocess, SourceAddress,TargetProcess,TargetAddress,Size,KernelMode,&Resualt)`

目的进程的PEPROCESS和地址，源进程的PEPROCESS和地址，写入长度

#### PsLookupThreadByThreadId

`PsLookupThreadByThreadId(Tid, &ethread)`

经Tid对应的 ETHREAD赋值为 ethread

#### IoThreadToProcess

`IoThreadToProcess(ethrd)`

返回ETHREAD结构体的PEPROCESS
