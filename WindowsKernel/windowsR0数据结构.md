#### PEB与TEB

PEB，进程环境块 `（Process Environment Block）`，用于存储进程状态信息和进程所需的各种数据。每个进程都有一个对应的 `PEB`结构体。

```
4: kd> dt _peb
nt!_PEB
   +0x000 InheritedAddressSpace : UChar
   +0x001 ReadImageFileExecOptions : UChar
   +0x002 BeingDebugged    : UChar
   +0x003 BitField         : UChar
   +0x003 ImageUsesLargePages : Pos 0, 1 Bit
   +0x003 IsProtectedProcess : Pos 1, 1 Bit
   +0x003 IsImageDynamicallyRelocated : Pos 2, 1 Bit
   +0x003 SkipPatchingUser32Forwarders : Pos 3, 1 Bit
   +0x003 IsPackagedProcess : Pos 4, 1 Bit
   +0x003 IsAppContainer   : Pos 5, 1 Bit
   +0x003 IsProtectedProcessLight : Pos 6, 1 Bit
   +0x003 IsLongPathAwareProcess : Pos 7, 1 Bit
   +0x004 Padding0         : [4] UChar
   +0x008 Mutant           : Ptr64 Void
   +0x010 ImageBaseAddress : Ptr64 Void
   +0x018 Ldr              : Ptr64 _PEB_LDR_DATA
   +0x020 ProcessParameters : Ptr64 _RTL_USER_PROCESS_PARAMETERS
   +0x028 SubSystemData    : Ptr64 Void
   +0x030 ProcessHeap      : Ptr64 Void
   +0x038 FastPebLock      : Ptr64 _RTL_CRITICAL_SECTION
   +0x040 AtlThunkSListPtr : Ptr64 _SLIST_HEADER
   +0x048 IFEOKey          : Ptr64 Void
   +0x050 CrossProcessFlags : Uint4B
   +0x050 ProcessInJob     : Pos 0, 1 Bit
   +0x050 ProcessInitializing : Pos 1, 1 Bit
   +0x050 ProcessUsingVEH  : Pos 2, 1 Bit
   +0x050 ProcessUsingVCH  : Pos 3, 1 Bit
   +0x050 ProcessUsingFTH  : Pos 4, 1 Bit
   +0x050 ProcessPreviouslyThrottled : Pos 5, 1 Bit
   +0x050 ProcessCurrentlyThrottled : Pos 6, 1 Bit
   +0x050 ProcessImagesHotPatched : Pos 7, 1 Bit
   +0x050 ReservedBits0    : Pos 8, 24 Bits
   +0x054 Padding1         : [4] UChar
   +0x058 KernelCallbackTable : Ptr64 Void
   +0x058 UserSharedInfoPtr : Ptr64 Void
   +0x060 SystemReserved   : Uint4B
   +0x064 AtlThunkSListPtr32 : Uint4B
   +0x068 ApiSetMap        : Ptr64 Void
   +0x070 TlsExpansionCounter : Uint4B
   +0x074 Padding2         : [4] UChar
   +0x078 TlsBitmap        : Ptr64 Void
   +0x080 TlsBitmapBits    : [2] Uint4B
   +0x088 ReadOnlySharedMemoryBase : Ptr64 Void
   +0x090 SharedData       : Ptr64 Void
   +0x098 ReadOnlyStaticServerData : Ptr64 Ptr64 Void
   +0x0a0 AnsiCodePageData : Ptr64 Void
   +0x0a8 OemCodePageData  : Ptr64 Void
   +0x0b0 UnicodeCaseTableData : Ptr64 Void
   +0x0b8 NumberOfProcessors : Uint4B
   +0x0bc NtGlobalFlag     : Uint4B
   +0x0c0 CriticalSectionTimeout : _LARGE_INTEGER
   +0x0c8 HeapSegmentReserve : Uint8B
   +0x0d0 HeapSegmentCommit : Uint8B
   +0x0d8 HeapDeCommitTotalFreeThreshold : Uint8B
   +0x0e0 HeapDeCommitFreeBlockThreshold : Uint8B
   +0x0e8 NumberOfHeaps    : Uint4B
   +0x0ec MaximumNumberOfHeaps : Uint4B
   +0x0f0 ProcessHeaps     : Ptr64 Ptr64 Void
   +0x0f8 GdiSharedHandleTable : Ptr64 Void
   +0x100 ProcessStarterHelper : Ptr64 Void
   +0x108 GdiDCAttributeList : Uint4B
   +0x10c Padding3         : [4] UChar
   +0x110 LoaderLock       : Ptr64 _RTL_CRITICAL_SECTION
   +0x118 OSMajorVersion   : Uint4B
   +0x11c OSMinorVersion   : Uint4B
   +0x120 OSBuildNumber    : Uint2B
   +0x122 OSCSDVersion     : Uint2B
   +0x124 OSPlatformId     : Uint4B
   +0x128 ImageSubsystem   : Uint4B
   +0x12c ImageSubsystemMajorVersion : Uint4B
   +0x130 ImageSubsystemMinorVersion : Uint4B
   +0x134 Padding4         : [4] UChar
   +0x138 ActiveProcessAffinityMask : Uint8B
   +0x140 GdiHandleBuffer  : [60] Uint4B
   +0x230 PostProcessInitRoutine : Ptr64     void 
   +0x238 TlsExpansionBitmap : Ptr64 Void
   +0x240 TlsExpansionBitmapBits : [32] Uint4B
   +0x2c0 SessionId        : Uint4B
   +0x2c4 Padding5         : [4] UChar
   +0x2c8 AppCompatFlags   : _ULARGE_INTEGER
   +0x2d0 AppCompatFlagsUser : _ULARGE_INTEGER
   +0x2d8 pShimData        : Ptr64 Void
   +0x2e0 AppCompatInfo    : Ptr64 Void
   +0x2e8 CSDVersion       : _UNICODE_STRING
   +0x2f8 ActivationContextData : Ptr64 _ACTIVATION_CONTEXT_DATA
   +0x300 ProcessAssemblyStorageMap : Ptr64 _ASSEMBLY_STORAGE_MAP
   +0x308 SystemDefaultActivationContextData : Ptr64 _ACTIVATION_CONTEXT_DATA
   +0x310 SystemAssemblyStorageMap : Ptr64 _ASSEMBLY_STORAGE_MAP
   +0x318 MinimumStackCommit : Uint8B
   +0x320 SparePointers    : [4] Ptr64 Void
   +0x340 SpareUlongs      : [5] Uint4B
   +0x358 WerRegistrationData : Ptr64 Void
   +0x360 WerShipAssertPtr : Ptr64 Void
   +0x368 pUnused          : Ptr64 Void
   +0x370 pImageHeaderHash : Ptr64 Void
   +0x378 TracingFlags     : Uint4B
   +0x378 HeapTracingEnabled : Pos 0, 1 Bit
   +0x378 CritSecTracingEnabled : Pos 1, 1 Bit
   +0x378 LibLoaderTracingEnabled : Pos 2, 1 Bit
   +0x378 SpareTracingBits : Pos 3, 29 Bits
   +0x37c Padding6         : [4] UChar
   +0x380 CsrServerReadOnlySharedMemoryBase : Uint8B
   +0x388 TppWorkerpListLock : Uint8B
   +0x390 TppWorkerpList   : _LIST_ENTRY
   +0x3a0 WaitOnAddressHashTable : [128] Ptr64 Void
   +0x7a0 TelemetryCoverageHeader : Ptr64 Void
   +0x7a8 CloudFileFlags   : Uint4B
   +0x7ac CloudFileDiagFlags : Uint4B
   +0x7b0 PlaceholderCompatibilityMode : Char
   +0x7b1 PlaceholderCompatibilityModeReserved : [7] Char
   +0x7b8 LeapSecondData   : Ptr64 _LEAP_SECOND_DATA
   +0x7c0 LeapSecondFlags  : Uint4B
   +0x7c0 SixtySecondEnabled : Pos 0, 1 Bit
   +0x7c0 Reserved         : Pos 1, 31 Bits
   +0x7c4 NtGlobalFlag2    : Uint4B
```

TEB，线程环境块 `（Thread Environment Block）`，用于存储线程状态信息和线程所需的各种数据。每个线程同样都有一个对应的 `TEB`结构体。

```
4: kd> dt _teb
nt!_TEB
   +0x000 NtTib            : _NT_TIB
   +0x038 EnvironmentPointer : Ptr64 Void
   +0x040 ClientId         : _CLIENT_ID
   +0x050 ActiveRpcHandle  : Ptr64 Void
   +0x058 ThreadLocalStoragePointer : Ptr64 Void
   +0x060 ProcessEnvironmentBlock : Ptr64 _PEB
   +0x068 LastErrorValue   : Uint4B
   +0x06c CountOfOwnedCriticalSections : Uint4B
   +0x070 CsrClientThread  : Ptr64 Void
   +0x078 Win32ThreadInfo  : Ptr64 Void
   +0x080 User32Reserved   : [26] Uint4B
   +0x0e8 UserReserved     : [5] Uint4B
   +0x100 WOW32Reserved    : Ptr64 Void
   +0x108 CurrentLocale    : Uint4B
   +0x10c FpSoftwareStatusRegister : Uint4B
   +0x110 ReservedForDebuggerInstrumentation : [16] Ptr64 Void
   +0x190 SystemReserved1  : [30] Ptr64 Void
   +0x280 PlaceholderCompatibilityMode : Char
   +0x281 PlaceholderHydrationAlwaysExplicit : UChar
   +0x282 PlaceholderReserved : [10] Char
   +0x28c ProxiedProcessId : Uint4B
   +0x290 _ActivationStack : _ACTIVATION_CONTEXT_STACK
   +0x2b8 WorkingOnBehalfTicket : [8] UChar
   +0x2c0 ExceptionCode    : Int4B
   +0x2c4 Padding0         : [4] UChar
   +0x2c8 ActivationContextStackPointer : Ptr64 _ACTIVATION_CONTEXT_STACK
   +0x2d0 InstrumentationCallbackSp : Uint8B
   +0x2d8 InstrumentationCallbackPreviousPc : Uint8B
   +0x2e0 InstrumentationCallbackPreviousSp : Uint8B
   +0x2e8 TxFsContext      : Uint4B
   +0x2ec InstrumentationCallbackDisabled : UChar
   +0x2ed UnalignedLoadStoreExceptions : UChar
   +0x2ee Padding1         : [2] UChar
   +0x2f0 GdiTebBatch      : _GDI_TEB_BATCH
   +0x7d8 RealClientId     : _CLIENT_ID
   +0x7e8 GdiCachedProcessHandle : Ptr64 Void
   +0x7f0 GdiClientPID     : Uint4B
   +0x7f4 GdiClientTID     : Uint4B
   +0x7f8 GdiThreadLocalInfo : Ptr64 Void
   +0x800 Win32ClientInfo  : [62] Uint8B
   +0x9f0 glDispatchTable  : [233] Ptr64 Void
   +0x1138 glReserved1      : [29] Uint8B
   +0x1220 glReserved2      : Ptr64 Void
   +0x1228 glSectionInfo    : Ptr64 Void
   +0x1230 glSection        : Ptr64 Void
   +0x1238 glTable          : Ptr64 Void
   +0x1240 glCurrentRC      : Ptr64 Void
   +0x1248 glContext        : Ptr64 Void
   +0x1250 LastStatusValue  : Uint4B
   +0x1254 Padding2         : [4] UChar
   +0x1258 StaticUnicodeString : _UNICODE_STRING
   +0x1268 StaticUnicodeBuffer : [261] Wchar
   +0x1472 Padding3         : [6] UChar
   +0x1478 DeallocationStack : Ptr64 Void
   +0x1480 TlsSlots         : [64] Ptr64 Void
   +0x1680 TlsLinks         : _LIST_ENTRY
   +0x1690 Vdm              : Ptr64 Void
   +0x1698 ReservedForNtRpc : Ptr64 Void
   +0x16a0 DbgSsReserved    : [2] Ptr64 Void
   +0x16b0 HardErrorMode    : Uint4B
   +0x16b4 Padding4         : [4] UChar
   +0x16b8 Instrumentation  : [11] Ptr64 Void
   +0x1710 ActivityId       : _GUID
   +0x1720 SubProcessTag    : Ptr64 Void
   +0x1728 PerflibData      : Ptr64 Void
   +0x1730 EtwTraceData     : Ptr64 Void
   +0x1738 WinSockData      : Ptr64 Void
   +0x1740 GdiBatchCount    : Uint4B
   +0x1744 CurrentIdealProcessor : _PROCESSOR_NUMBER
   +0x1744 IdealProcessorValue : Uint4B
   +0x1744 ReservedPad0     : UChar
   +0x1745 ReservedPad1     : UChar
   +0x1746 ReservedPad2     : UChar
   +0x1747 IdealProcessor   : UChar
   +0x1748 GuaranteedStackBytes : Uint4B
   +0x174c Padding5         : [4] UChar
   +0x1750 ReservedForPerf  : Ptr64 Void
   +0x1758 ReservedForOle   : Ptr64 Void
   +0x1760 WaitingOnLoaderLock : Uint4B
   +0x1764 Padding6         : [4] UChar
   +0x1768 SavedPriorityState : Ptr64 Void
   +0x1770 ReservedForCodeCoverage : Uint8B
   +0x1778 ThreadPoolData   : Ptr64 Void
   +0x1780 TlsExpansionSlots : Ptr64 Ptr64 Void
   +0x1788 DeallocationBStore : Ptr64 Void
   +0x1790 BStoreLimit      : Ptr64 Void
   +0x1798 MuiGeneration    : Uint4B
   +0x179c IsImpersonating  : Uint4B
   +0x17a0 NlsCache         : Ptr64 Void
   +0x17a8 pShimData        : Ptr64 Void
   +0x17b0 HeapData         : Uint4B
   +0x17b4 Padding7         : [4] UChar
   +0x17b8 CurrentTransactionHandle : Ptr64 Void
   +0x17c0 ActiveFrame      : Ptr64 _TEB_ACTIVE_FRAME
   +0x17c8 FlsData          : Ptr64 Void
   +0x17d0 PreferredLanguages : Ptr64 Void
   +0x17d8 UserPrefLanguages : Ptr64 Void
   +0x17e0 MergedPrefLanguages : Ptr64 Void
   +0x17e8 MuiImpersonation : Uint4B
   +0x17ec CrossTebFlags    : Uint2B
   +0x17ec SpareCrossTebBits : Pos 0, 16 Bits
   +0x17ee SameTebFlags     : Uint2B
   +0x17ee SafeThunkCall    : Pos 0, 1 Bit
   +0x17ee InDebugPrint     : Pos 1, 1 Bit
   +0x17ee HasFiberData     : Pos 2, 1 Bit
   +0x17ee SkipThreadAttach : Pos 3, 1 Bit
   +0x17ee WerInShipAssertCode : Pos 4, 1 Bit
   +0x17ee RanProcessInit   : Pos 5, 1 Bit
   +0x17ee ClonedThread     : Pos 6, 1 Bit
   +0x17ee SuppressDebugMsg : Pos 7, 1 Bit
   +0x17ee DisableUserStackWalk : Pos 8, 1 Bit
   +0x17ee RtlExceptionAttached : Pos 9, 1 Bit
   +0x17ee InitialThread    : Pos 10, 1 Bit
   +0x17ee SessionAware     : Pos 11, 1 Bit
   +0x17ee LoadOwner        : Pos 12, 1 Bit
   +0x17ee LoaderWorker     : Pos 13, 1 Bit
   +0x17ee SkipLoaderInit   : Pos 14, 1 Bit
   +0x17ee SpareSameTebBits : Pos 15, 1 Bit
   +0x17f0 TxnScopeEnterCallback : Ptr64 Void
   +0x17f8 TxnScopeExitCallback : Ptr64 Void
   +0x1800 TxnScopeContext  : Ptr64 Void
   +0x1808 LockCount        : Uint4B
   +0x180c WowTebOffset     : Int4B
   +0x1810 ResourceRetValue : Ptr64 Void
   +0x1818 ReservedForWdf   : Ptr64 Void
   +0x1820 ReservedForCrt   : Uint8B
   +0x1828 EffectiveContainerId : _GUID
```

**TEB** 和 **PEB** 是用户模式结构，提供线程和进程的运行时信息

#### PCB 与 TCB

这两个数据结构，进程控制块（Process Contral Block）和线程控制块（Thread Contral Block）处于内核中

**TCB** 和 **PCB** 是内核模式结构，管理线程和进程的生命周期和调度。

##### EPROCESS

Windows 内核中的一个数据结构，表示一个进程对象。它用于管理和维护与系统中每个进程相关的信息

* `PsGetCurrentProcess()`: 获取当前进程的 `EPROCESS` 结构。
* `PsLookupProcessByProcessId()`: 通过进程 ID 查找 `EPROCESS` 结构。
* `ObReferenceObjectByHandle()`: 通过进程句柄获取 `EPROCESS`。

未公开，简化版本

```
typedef struct _EPROCESS {
    KPROCESS Pcb;                  // 内核调度块 (KPROCESS)
    EX_PUSH_LOCK ProcessLock;       // 进程锁，用于同步
    LARGE_INTEGER CreateTime;       // 进程创建时间
    LARGE_INTEGER ExitTime;         // 进程退出时间
    PVOID UniqueProcessId;          // 进程 PID
    LIST_ENTRY ActiveProcessLinks;  // 活动进程的链表
    PVOID QuotaBlock;               // 用于配额管理
    PVOID DebugPort;                // 调试端口
    PVOID ExceptionPort;            // 异常端口
    HANDLE Token;                   // 进程的访问令牌
    ULONG WorkingSetPage;           // 工作集页
    LIST_ENTRY ThreadListHead;      // 线程链表头
    PVOID VadRoot;                  // VAD 树根，用于虚拟内存管理
    PVOID Win32Process;             // Win32 子系统进程信息
    PVOID Job;                      // 进程所属的作业对象
    UNICODE_STRING ImageFileName;   // 进程的图像文件名
    ULONG ExitStatus;               // 进程退出状态
    PEB *Peb;                       // 用户态的 PEB
    // 其他字段 ...
} EPROCESS, *PEPROCESS;
```

不同操作系统EPROCESS结构体不同，需要通过API函数来获取对应信息

#### LIST_ENTRY

内核中是无法使用STL中数据结构，LIST_ENTRY作为内核中重要的一个结构体，是一个双向链表

```c
typedef struct _LIST_ENTRY
{
 	struct _LIST_ENTRY *Flink;   // 当前节点的后一个节点
	struct _LIST_ENTRY *Blink;   // 当前节点的前一个结点
}LIST_ENTRY, *PLIST_ENTRY;
```

一个通过LIST_ENTRY操作数据的示例：

```c
typedef struct _MyStruct
{
	ULONG x;
	ULONG y;
	LIST_ENTRY lpListEntry;
}MyStruct, *pMyStruct;

NTSTATUS DriverEntry(IN PDRIVER_OBJECT Driver, PUNICODE_STRING RegistryPath) 
{
	// 初始化头节点
	LIST_ENTRY ListHeader = { 0 };
	InitializeListHead(&ListHeader);

	// 定义链表元素
	MyStruct testA = { 0 };
	MyStruct testB = { 0 };
	MyStruct testC = { 0 };
	testA.x = 100;
	testA.y = 200;
	testB.x = 1000;
	testB.y = 2000;
	testC.x = 10000;
	testC.y = 20000;


	// 分别插入节点到头部和尾部
	InsertHeadList(&ListHeader, &testA.lpListEntry);
	InsertTailList(&ListHeader, &testB.lpListEntry);
	InsertTailList(&ListHeader, &testC.lpListEntry);

	// 节点不为空 则 移除一个节点
	if (IsListEmpty(&ListHeader) == FALSE)
	{
		RemoveEntryList(&testA.lpListEntry);
	}

	// 输出链表数据
	PLIST_ENTRY pListEntry = NULL;
	pListEntry = ListHeader.Flink;

	while (pListEntry != &ListHeader)
	{
		// 计算出成员距离结构体顶部内存距离
		pMyStruct ptr = CONTAINING_RECORD(pListEntry, MyStruct, lpListEntry);
		DbgPrint("节点元素X = %d 节点元素Y = %d \n", ptr->x, ptr->y);
		// 得到下一个元素地址
		pListEntry = pListEntry->Flink;
	}
	Driver->DriverUnload = UnDriver;
	return STATUS_SUCCESS;
}
```

使用 `InitializeListHead(&ListHeader);`初始化头节点，利用API函数对链表进行操作

* InsertHeadList

  ```
  VOID InsertHeadList(
      _Inout_ PLIST_ENTRY ListHead, //指向双向链表头部的指针。
      _Out_ PLIST_ENTRY Entry	//指向要插入到链表头部的元素的指针
  );
  ```

  通过结构体中的LIST_ENTRY来链接结构体
* ...

使用以上API对LIST_ENTRY进行操作

`CONTAINING_RECORD`宏的作用是根据包含结构体中某个成员变量的地址，找到包含结构体的起始地址。

```c
#define CONTAINING_RECORD(address, type, field) \
    ((type *)((PCHAR)(address) - (ULONG_PTR)(&((type *)0)->field)))
// 示例
CONTAINING_RECORD(pListEntry, MyStruct, lpListEntry);
```

* `address`：要获取包含结构体的成员变量地址。
* `type`：包含结构体的类型。
* `field`：包含结构体中的成员变量名称。

该宏的原理是通过对空指针指向的结构体的利用，[CONTAINING_RECORD宏原理与使用详解_containing record-CSDN博客](https://blog.csdn.net/zyhse/article/details/109246875)

#### IRP

IRP（I/O Request Packet）是 Windows 驱动程序开发中用于表示输入/输出请求的数据结构。每个 I/O 请求都由一个 IRP 结构体表示，该结构包含了有关请求的信息，包括请求类型、缓冲区、传输方向等。

```
typedef struct _IRP {
  CSHORT                    Type;
  USHORT                    Size;
  PMDL                      MdlAddress;
  ULONG                     Flags;
  union {
    struct _IRP     *MasterIrp;
    __volatile LONG IrpCount;
    PVOID           SystemBuffer;
  } AssociatedIrp;
  LIST_ENTRY                ThreadListEntry;
  IO_STATUS_BLOCK           IoStatus;
  KPROCESSOR_MODE           RequestorMode;
  BOOLEAN                   PendingReturned;
  CHAR                      StackCount;
  CHAR                      CurrentLocation;
  BOOLEAN                   Cancel;
  KIRQL                     CancelIrql;
  CCHAR                     ApcEnvironment;
  UCHAR                     AllocationFlags;
  union {
    PIO_STATUS_BLOCK UserIosb;
    PVOID            IoRingContext;
  };
  PKEVENT                   UserEvent;
  union {
    struct {
      union {
        PIO_APC_ROUTINE UserApcRoutine;
        PVOID           IssuingProcess;
      };
      union {
        PVOID                 UserApcContext;
#if ...
        _IORING_OBJECT        *IoRing;
#else
        struct _IORING_OBJECT *IoRing;
#endif
      };
    } AsynchronousParameters;
    LARGE_INTEGER AllocationSize;
  } Overlay;
  __volatile PDRIVER_CANCEL CancelRoutine;
  PVOID                     UserBuffer;
  union {
    struct {
      union {
        KDEVICE_QUEUE_ENTRY DeviceQueueEntry;
        struct {
          PVOID DriverContext[4];
        };
      };
      PETHREAD     Thread;
      PCHAR        AuxiliaryBuffer;
      struct {
        LIST_ENTRY ListEntry;
        union {
          struct _IO_STACK_LOCATION *CurrentStackLocation;
          ULONG                     PacketType;
        };
      };
      PFILE_OBJECT OriginalFileObject;
    } Overlay;
    KAPC  Apc;
    PVOID CompletionKey;
  } Tail;
} IRP;
```

#### IO_STACK_LOCATION

是 `IoGetCurrentIrpStackLocation`函数的返回值，该结构体定义 [I/O 堆栈位置](https://learn.microsoft.com/zh-cn/windows-hardware/drivers/kernel/i-o-stack-locations)，它是与每个 IRP 关联的 I/O 堆栈中的条目。 IRP 中的每个 I/O 堆栈位置都有一些常见成员和一些特定于请求类型的成员

详情见[IO_STACK_LOCATION （wdm.h） - Windows drivers | Microsoft Learn](https://learn.microsoft.com/zh-cn/windows-hardware/drivers/ddi/wdm/ns-wdm-_io_stack_location)

驱动程序应为每个IRP调用 `IoGetCurrentIrpStackLocation`以获取当前请求的任何参数。

#### 内核中的自旋锁结构

自旋锁是为了解决内核链表读写时存在线程同步问题，解决多线程同步问题必须要用锁，通常使用
自旋锁，自旋锁是内核中提供的一种高IRQL锁，用同步以及独占的方式访问某个资源。

示例：

```c
// 定义全局链表和全局锁
LIST_ENTRY my_list_header;
KSPIN_LOCK my_list_lock;

 // 初始化
void Init()
{
    InitializeListHead(&my_list_header);
    KeInitializeSpinLock(&my_list_lock);	//初始化自旋锁
}

// 先加锁，后操作，再解锁
void function_ins()
{
    KIRQL Irql;
    // 加锁
    KeAcquireSpinLock(&my_list_lock, &Irql);
    //针对my_list_lock的操作
    DbgPrint("锁内部执行 \n");
    // 释放锁
    KeReleaseSpinLock(&my_list_lock, Irql);
}
```

#### 内核回调

##### OB_OPERATION_REGISTRATION

```
typedef struct _OB_OPERATION_REGISTRATION {
    _In_ POBJECT_TYPE*		     ObjectType;
    _In_ OB_OPERATION                Operations;
    _In_ POB_PRE_OPERATION_CALLBACK  PreOperation;
    _In_ POB_POST_OPERATION_CALLBACK PostOperation;
} OB_OPERATION_REGISTRATION, *POB_OPERATION_REGISTRATION;
```

* ObjectType：一个枚举类型，表示要监控的操作类型，具体取值如下：*  **`OB_OPERATION_HANDLE_CREATE`** ：表示创建对象句柄的操作，如创建文件、进程、线程等对象时对应的句柄创建操作。
* Operations：表示要监控的操作类型

  ```
  OB_OPERATION_HANDLE_DUPLICATE		表示复制对象句柄的操作。
  OB_OPERATION_HANDLE_CLOSE		表示关闭对象句柄的操作。
  OB_OPERATION_HANDLE_WAIT		表示等待对象句柄的操作。
  OB_OPERATION_HANDLE_SET_INFORMATION	表示设置对象句柄信息的操作。
  OB_OPERATION_HANDLE_QUERY_INFORMATION	表示查询对象句柄信息的操作。
  OB_OPERATION_HANDLE_OPERATION		表示其他未明确列举的对象句柄操作。
  ```
* PreOperation：函数指针，请求的操作发生之前调用此回调函数
* PostOperation：函数指针，请求的操作发生之后调用此回调函数

##### _OB_CALLBACK_REGISTRATION

```
typedef struct _OB_CALLBACK_REGISTRATION {
    _In_ USHORT                     Version;				// 结构体版本
    _In_ USHORT                     OperationRegistrationCount;		// 注册的操作回调数量,即OperationRegistration数组中的元素个数。
    _In_ UNICODE_STRING             Altitude;				// 指定驱动程序的优先级
    _In_ PVOID                      RegistrationContext;		// 上下文信息，定义后传递到回调中使用
    _In_ OB_OPERATION_REGISTRATION  *OperationRegistration;		// 指定具体的操作回调函数及相关信息
} OB_CALLBACK_REGISTRATION, *POB_CALLBACK_REGISTRATION;
```

##### OB_PRE_OPERATION_INFORMATION

在ObRegisterCallbacks绑定的回调函数中，可以接受两个外部参数，OB_CALLBACK_REGISTRATION结构体的RegistrationContext和OB_PRE_OPERATION_INFORMATION

```
typedef struct _OB_PRE_OPERATION_INFORMATION {
    _In_ OB_OPERATION           Operation;
    union {
        _In_ ULONG Flags;
        struct {
            _In_ ULONG KernelHandle:1;
            _In_ ULONG Reserved:31;
        };
    };
    _In_ PVOID                         Object;		// 指向调用进程的EPROCESS结构体
    _In_ POBJECT_TYPE                  ObjectType;
    _Out_ PVOID                        CallContext;
    _In_ POB_PRE_OPERATION_PARAMETERS  Parameters;
} OB_PRE_OPERATION_INFORMATION, *POB_PRE_OPERATION_INFORMATION;
```

其Parameters成员为OB_PRE_OPERATION_PARAMETERS联合，可能处于两种状态

```
typedef union _OB_PRE_OPERATION_PARAMETERS {
    _Inout_ OB_PRE_CREATE_HANDLE_INFORMATION        CreateHandleInformation;
    _Inout_ OB_PRE_DUPLICATE_HANDLE_INFORMATION     DuplicateHandleInformation;
} OB_PRE_OPERATION_PARAMETERS, *POB_PRE_OPERATION_PARAMETERS;
```

同理，上述为操作前结构体，操作后结构体POST类与上边类似
