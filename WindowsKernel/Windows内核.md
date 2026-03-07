#### 内存分布

32位：

* 用户空间：`0x00000000` ~ `0x7fffffff`
* 内核空间：`0x80000000` ~ `0xffffffff`

64位：

* 用户空间：`0x00000000 00000000` ~ `0x0000ffff ffffffff`
* 内核空间：`0x0000ffff ffffffff` ~ `0xffffffff ffffffff`

#### 调试

在VMware中搭建win10虚拟机，物理机安装wingdb，搭建双机调试

使用debugview查看内核输出信息，需要勾选Capture Kernel等选项，否则无法捕获信息

使用KMD Manager来装载驱动，使用服务可能导致开机启动服务导致蓝屏，蓝屏导致重启，无法正常启动

都使用管理员权限来运行

#### 驱动项目设置

见Windows内核安全编程技术实践

#### 加载驱动

禁用驱动签名保护 `bcdedit.exe /set nointegritychecks on`

微软在x64系统中推出了 DSE (Driver Signature Enforcement)，该保护机制的核心就是任何驱动程序或者是第三方驱动如果想要在正常模式下被加载则必须要经过微软的认证，当驱动程序被加载到内存时会验证签名的正确性，如果签名不正常则系统会拒绝运行驱动，这种机制也被称为驱动强制签名，该机制的作用是保护系统免受恶意软件的破坏，是提高系统安全性的一种手段。
该验证机制即便是在调试模式也需要强制签名，对于一名驱动开发者来说是很麻烦的一件事情，而签名的验证则是在加载时验证驱动入口_KLDR_DATA_TABLE_ENTRY 里面的Flags 标志，如果此标志被pLdrData->Flags | 0x20置位，则在调试模式下就不会在验证签名了，省去了重复签名的麻烦。

```c
BOOLEAN BypassCheckSign(PDRIVER_OBJECT pDriverObject)
{
#ifdef _WIN64
    typedef struct _KLDR_DATA_TABLE_ENTRY
    {
        LIST_ENTRY listEntry;
        ULONG64 __Undefined1;
        ULONG64 __Undefined2;
        ULONG64 __Undefined3;
        ULONG64 NonPagedDebugInfo;
        ULONG64 DllBase;
        ULONG64 EntryPoint;
        ULONG SizeOfImage;
        UNICODE_STRING path;
        UNICODE_STRING name;
        ULONG   Flags;
        USHORT  LoadCount;
        USHORT  __Undefined5;
        ULONG64 __Undefined6;
        ULONG   CheckSum;
        ULONG   __padding1;
        ULONG   TimeDateStamp;
        ULONG   __padding2;
    } KLDR_DATA_TABLE_ENTRY, * PKLDR_DATA_TABLE_ENTRY;
#else
    typedef struct _KLDR_DATA_TABLE_ENTRY
    {
        LIST_ENTRY listEntry;
        ULONG unknown1;
        ULONG unknown2;
        ULONG unknown3;
        ULONG unknown4;
        ULONG unknown5;
        ULONG unknown6;
        ULONG unknown7;
        UNICODE_STRING path;
        UNICODE_STRING name;
        ULONG   Flags;
    } KLDR_DATA_TABLE_ENTRY, * PKLDR_DATA_TABLE_ENTRY;
#endif
    PKLDR_DATA_TABLE_ENTRY pLdrData = (PKLDR_DATA_TABLE_ENTRY)pDriverObject->DriverSection;
    pLdrData->Flags = pLdrData->Flags | 0x20;
    return TRUE;
}
```

在DriverEntry函数开头调用

```c
BypassCheckSign(Driver);
```

绕过强制签名保护

注：经过测试，发现必须通过高级启动来彻底禁用DSE，前两种操作有时失效

#### DriverEntry

DriverEntry作为驱动程序的入口点，原型为：

```c
NTSTATUS DriverEntry(
  _In_ PDRIVER_OBJECT  DriverObject,
  _In_ PUNICODE_STRING RegistryPath
);
```

* *DriverObject* [in]：指向 [DRIVER_OBJECT](https://learn.microsoft.com/zh-cn/windows-hardware/drivers/ddi/wdm/ns-wdm-_driver_object) 结构的指针，该结构表示驱动程序的 WDM 驱动程序对象。
* *RegistryPath* [in]：指向 [UNICODE_STRING](https://learn.microsoft.com/zh-cn/windows-hardware/drivers/ddi/wudfwdm/ns-wudfwdm-_unicode_string) 结构的指针，该结构指定注册表中驱动程序 [的 Parameters 键](https://learn.microsoft.com/zh-cn/windows-hardware/drivers/wdf/introduction-to-registry-keys-for-drivers) 的路径。

#### 驱动对象与设备对象

[DRIVER_OBJECT](https://learn.microsoft.com/zh-cn/windows-hardware/drivers/ddi/wdm/ns-wdm-_driver_object)

```c
typedef struct _DRIVER_OBJECT {
    CSHORT Type;                                // 驱动类型
    CSHORT Size;                                // 驱动大小
    PDEVICE_OBJECT DeviceObject;                // 驱动对象
    ULONG Flags;                                // 驱动的标志
    PVOID DriverStart;                          // 驱动的起始位置
    ULONG DriverSize;                           // 驱动的大小
    PVOID DriverSection;                        // 指向驱动程序映像的内存区对象
    PDRIVER_EXTENSION DriverExtension;          // 驱动的扩展空间
    UNICODE_STRING DriverName;                  // 驱动名字
    PUNICODE_STRING HardwareDatabase;
    PFAST_IO_DISPATCH FastIoDispatch;
    PDRIVER_INITIALIZE DriverInit;
    PDRIVER_STARTIO DriverStartIo;
    PDRIVER_UNLOAD DriverUnload;                 // 驱动对象的卸载地址
    PDRIVER_DISPATCH MajorFunction[IRP_MJ_MAXIMUM_FUNCTION + 1];
} DRIVER_OBJECT;
```

该驱动由内核在初始化时创建，启动DeviceObject字段指向第一个设备对象

```c
typedef struct DECLSPEC_ALIGN(MEMORY_ALLOCATION_ALIGNMENT) _DEVICE_OBJECT {
    CSHORT Type;
    USHORT Size;
    LONG ReferenceCount;
    struct _DRIVER_OBJECT *DriverObject;
    struct _DEVICE_OBJECT *NextDevice;
    struct _DEVICE_OBJECT *AttachedDevice;
    struct _IRP *CurrentIrp;
    PIO_TIMER Timer;
    ULONG Flags;                                // See above:  DO_...
    ULONG Characteristics;                      // See ntioapi:  FILE_...
    __volatile PVPB Vpb;
    PVOID DeviceExtension;
    DEVICE_TYPE DeviceType;
    CCHAR StackSize;
    union {
        LIST_ENTRY ListEntry;
        WAIT_CONTEXT_BLOCK Wcb;
    } Queue;
    ULONG AlignmentRequirement;
    KDEVICE_QUEUE DeviceQueue;
    KDPC Dpc;

    //
    //  The following field is for exclusive use by the filesystem to keep
    //  track of the number of Fsp threads currently using the device
    //

    ULONG ActiveThreadCount;
    PSECURITY_DESCRIPTOR SecurityDescriptor;
    KEVENT DeviceLock;

    USHORT SectorSize;
    USHORT Spare1;

    struct _DEVOBJ_EXTENSION  *DeviceObjectExtension;
    PVOID  Reserved;

} DEVICE_OBJECT;
```

每个驱动程序会创建一个或多个设备对象，用 DEVICE_OBJECT 数据结构表示。每个设备对象都会有一个指针指向下一个设备对象，最后一个设备对象指向空，因此就形成一个 设备链，由NextDevice成员变连接

#### 内核中字符串的转换方式

在内核中有ANSI_STRING和UNICODE_STRING两种字符串，分别代表 `char*`和 `wchar*`的字符串

初始化字符串：

```c
	// 定义内核字符串
	ANSI_STRING ansi;
	UNICODE_STRING unicode;
	UNICODE_STRING str;
	// 定义普通字符串
	char* char_string = "hello lyshark";
	wchar_t* wchar_string = (WCHAR*)"hello lyshark";
	// 初始化字符串的多种方式
	RtlInitAnsiString(&ansi, char_string);
	RtlInitUnicodeString(&unicode, wchar_string);
	RtlUnicodeStringInit(&str, L"hello lyshark");

	// 改变原始字符串（乱码位置，此处仅用于演示赋值方式）
	char_string[0] = (CHAR)"A";
	char_string[1] = (CHAR)"B";
	wchar_string[0] = (WCHAR)"A";
	wchar_string[2] = (WCHAR)"B";
	// char类型每个占用1字节
	// wchar类型每个占用2字节
	// 输出字符串 %Z
	DbgPrint("输出ANSI: %Z \n", &ansi);
	DbgPrint("输出WCHAR: %Z \n", &unicode);
	DbgPrint("输出字符串: %wZ \n", &str);
```

`L:"str"`形如这种，是代表wchar*，unicode字符串的意思

使用的API函数来转化和拷贝字符串，注意拷贝时，unicode字符串所占空间是ANSI字符串的二倍

#### IRP和派遣函数

I/O Request Package （输入输出请求包） 。应用程序与驱动程序通信时，应用程序会发出I/O请求，操作系统将I/O请求转化为相应的IRP数据，不同类型的IRP会根据类型传递到不同的派遣函数内。

IRP类型：

```c
IRP_MJ_CREATE	创建设备，如CreateFile
IRP_MJ_READ	读设备，如ReadFile
IRP_MJ_WRITE	写设备，如WriteFile
IRP_MJ_QUERY_INFORMATION	获取设备信息，如GetFileSize
IRP_MJ_SET_INFORMATION	设置设备信息，如SetFileSize
IRP_MJ_DEVICE_CONTROL	自定义操作，如DeviceIoControl
IRP_MJ_SYSTEM_CONTROL	系统内部产生的控制信息，类似于内核调用DeviceIoControl函数
IRP_MJ_CLOSE	关闭设备，如CloseHandle
IRP_MJ_CLEANUP	清除工作，如CloseHandle
IRP_MJ_SHUTDOWN	关闭系统前会产生此IRP
IRP_MJ_PNP	即插即用消息，NT驱动不支持，只有WDM驱动才支持
IRP_MJ_POWER	操作系统处理电源消息时，产生此IRP
```

个派遣函数本质并无差别，全看驱动代码怎么写

#### 为设备创建符号链接

将符号链接和设备对象关联起来，使得应用程序可以通过符号链接访问设备对象，例如使用

```c
NTSTATUS CreateDriverObject(IN PDRIVER_OBJECT pDriver)
{
	NTSTATUS Status;
	PDEVICE_OBJECT pDevObj;
	UNICODE_STRING DriverName;
	UNICODE_STRING SymLinkName;

	RtlInitUnicodeString(&DriverName, L"\\Device\\My_Device");

	Status = IoCreateDevice(pDriver, 0, &DriverName, FILE_DEVICE_UNKNOWN, 0, TRUE, &pDevObj);
	DbgPrint("命令 IoCreateDevice 状态: %d", Status);

	// DO_BUFFERED_IO 设置读写方式 Flags的三个不同的值分别为：DO_BUFFERED_IO、 DO_DIRECT_IO和0
	pDevObj->Flags |= DO_BUFFERED_IO;
	RtlInitUnicodeString(&SymLinkName, L"\\??\\My_Device");

	Status = IoCreateSymbolicLink(&SymLinkName, &DriverName);
	DbgPrint("当前命令IoCreateSymbolicLink状态: %d", Status);
	return STATUS_SUCCESS;
}
```

驱动对象有派遣函数，设备对象没有，所建立的符号链接是为驱动对象所创建的IoCreateDevice的作用只是初始化驱动对象

在 Windows 驱动程序开发中，一个符号链接可以与驱动程序中的不同设备对象关联，但最终所有的派遣函数都属于驱动程序，而不是与具体的设备对象直接关联。这意味着无论用户通过哪个设备对象访问驱动程序，最终都会通过驱动程序中的相同派遣函数来处理请求。

#### PIPE管道通信

在创建管道后可以使用 `[System.IO.Directory]: :GetFiles("\\.\\pipe\\")`命令查看当前创建好的管道

一开始以为，内核中驱动代码部分要先创建文件对象然后用户态才能通过CreateNamedPipe函数打开管道来通信，但实际上

在进行管道通信时，需要先在用户态打开管道，因为内核模式下的操作是在操作系统内核空间中执行的，操作系统期望内核模式下的操作是高效且可靠的。因此，在内核模式下，`ZwCreateFile` 函数打开的对象（比如文件、管道等）通常要求在操作之前已经存在，以确保内核操作的有效性。

#### SSDT

SSDT 是 Windows 内核中的一个表，用于存储系统服务调用的信息。它包含了系统中所有可用系统服务的索引和地址，允许用户态程序通过系统调用来请求操作系统内核提供的服务。每个系统服务都会被分配一个唯一的索引，用户态程序可以通过这些索引号来调用相应的系统服务。

ShadowSSDT 影子系统服务描述表，SSSDT其主要的作用是管理系统中的图形化界面，其Win32 子系统的内核实现是Win32k.sys 驱动，属于GUI线程的一部分，其自身没有导出表

KiSystemServiceRepeat函数时

```
.text:0000000140412184                               KiSystemServiceRepeat:                  ; CODE XREF: KiSystemCall64+BE8↓j
.text:0000000140412184 4C 8D 15 35 F7 9E 00          lea     r10, KeServiceDescriptorTable
.text:000000014041218B 4C 8D 1D AE A8 8E 00          lea     r11, KeServiceDescriptorTableShadow
```

KeServiceDescriptorTable是一个结构体占，0x20字节

```
typedef struct ServiceDescriptorTable {
	PVOID ServiceTableBase;
	PVOID ServiceCounterTable(0);
	unsigned int NumberOfServices;
	PVOID ParamTableBase;
};
```

ServiceTableBase字段为实际的SSDT表基址，即KiServiceTable。该结构体之后0x20字节为空，再之后为KiDebugTraps，用于存放处理中断的函数地址

KeServiceDescriptorTableShadow是一个未导出的结构体，但其前0x20字节和KeServiceDescriptorTable一样，其后0x20字节也是一个结构体，与KeServiceDescriptorTableShadow相仿，是关于GUI服务的一部分

由于这些函数的实现都在Win32k.sys 驱动中，所以函数实现无法通过winDbg查看，通过下载Win32k.sys反编译查看，W32pServiceTable，同KiServiceTable，存放了加密后的偏移，解密后偏移加W32pServiceTable基址即为真正服务函数地址

##### 前置知识

**MSR(Model-Specific Register)** 是一类寄存器,这类寄存器数量庞大,并且和处理器的model相关.提供对硬件和软件相关功能的一些控制.能够对一些硬件和软件的运行环境进行设置.

每个MSR是64位宽的，每个MSR都有它的的地址值(编号)。

对MSR操作使用两个指令进行读写，**rdmsr，**wrmsr****

由ecx寄存器提供需要访问的MSR地址值。用作读写：EAX表示低32位,EDX表示高32位。

64位和32位相同，只不过EAX和EDX的高32位会被清零

以NtWriteFile为例：

```
.text:00000001800A0090 4C 8B D1                      mov     r10, rcx                        ; NtWriteFile
.text:00000001800A0093 B8 08 00 00 00                mov     eax, 8
.text:00000001800A0098 F6 04 25 08 03 FE 7F 01       test    byte ptr ds:7FFE0308h, 1
.text:00000001800A00A0 75 03                         jnz     short loc_1800A00A5
.text:00000001800A00A0
.text:00000001800A00A2 0F 05                         syscall                                 ; Low latency system call
.text:00000001800A00A4 C3                            retn
.text:00000001800A00A4
.text:00000001800A00A5                               ; ---------------------------------------------------------------------------
.text:00000001800A00A5
.text:00000001800A00A5                               loc_1800A00A5:                          ; CODE XREF: NtWriteFile+10↑j
.text:00000001800A00A5 CD 2E                         int     2Eh                             ; DOS 2+ internal - EXECUTE COMMAND
.text:00000001800A00A5                                                                       ; DS:SI -> counted CR-terminated command string
.text:00000001800A00A5
.text:00000001800A00A7 C3                            retn
.text:00000001800A00A7
.text:00000001800A00A7                               NtWriteFile endp
```

有两种切换到内核模式的方法，这是[浅析Windows系统调用——2种切换到内核模式的方法_51CTO博客_切换为系统内核](https://blog.51cto.com/shayi1983/1710861)中的内容

1. 内存法（中断）：WriteFile() ->ntdll!NtWriteFile() -> ntdll!KiIntSystemCall() -> int 2Eh -> 查找 IDT （中断描述符表）的内存地址，偏移0x2E处 ->（内核模式）nt!KiSystemService()  -> nt!KiFastCallEntry() -> nt!NtWriteFile()
2. MSR寄存器法（快速法）：WriteFile() -> ntdll!NtWriteFile() ->  ntdll!KiFastSystemCall() -> 分别设置 IA32_SYSENTER_CS 寄存器的值为 Ring0 权限代码段描述符对应的段选择符；设置 IA32_SYSENTER_ESP 寄存器的值为 Ring0 权限的内核模式栈地址；设置 IA32_SYSENTER_EIP 寄存器指向 nt!KiFastCallEntry() 的起始地址 ->SYSENTER ->（内核模式）nt!KiFastCallEntry() ->  nt!NtWriteFile()

以上所述的都是32位，在64位下则是：

WriteFile()-> ntdll!NtWriteFile() -> syscall -> 设置 IA32_LSTAR MSR 寄存器 保存内核入口点地址 -> 进入内核 ->KiSystemCall64函数

在内核中调用KiSystemCall64函数后，按照如下所述完成系统调用

ntdll.dll中用户模式下，有部分需要切换到内核模式才能完成的函数，每个Nt函数都有一个同名称的 Zw函数 与其对应，二者在用户空间的入口点完全相同，微软将用户模式 Nt函数 和Zw函数 与内核模式对应 Nt函数强制关联在一起。

内核模式设备驱动程序不允许直接调用内核模式 Nt函数，而是需要通过 Zw函数 来间接调用 Nt函数

内核中的ZwWriteFile函数：

```
.text:00000001403FA900 48 8B C4                      mov     rax, rsp
.text:00000001403FA903 FA                            cli
.text:00000001403FA904 48 83 EC 10                   sub     rsp, 10h
.text:00000001403FA908 50                            push    rax
.text:00000001403FA909 9C                            pushfq
.text:00000001403FA90A 6A 10                         push    10h
.text:00000001403FA90C 48 8D 05 2D 88 00 00          lea     rax, KiServiceLinkage
.text:00000001403FA913 50                            push    rax
.text:00000001403FA914 B8 08 00 00 00                mov     eax, 8
.text:00000001403FA919 E9 62 74 01 00                jmp     KiServiceInternal
.text:00000001403FA919
.text:00000001403FA91E                               ; ---------------------------------------------------------------------------
.text:00000001403FA91E C3                            retn
.text:00000001403FA91E
.text:00000001403FA91E                               ZwWriteFile endp
```

将系统服务号，即SSDT表的对应索引放入到rax中，然后通过KiServiceInternal->KiSystemServiceStart->KiSystemServiceRepeat->直接通过一系列汇编指令跳转到Nt函数处

而用户态nt函数在ntdll.dll中通过syscall进入内核时，首先进入KiSystemCall64函数,[Windows10内核逆向-1-系统调用_kisystemservicecopyend-CSDN博客](https://blog.csdn.net/u013677637/article/details/126685425) 中有更详细的流程，这里只写关键部分

1. KiSystemCall保存Ring3环境

   ```
   text:0000000140411E00                               ; __unwind { // KiSystemServiceHandler
   .text:0000000140411E00 0F 01 F8                      swapgs
   .text:0000000140411E03 65 48 89 24 25 10 00 00 00    mov     gs:10h, rsp                     ; 保存R3 rsp,syscall不保存
   .text:0000000140411E0C 65 48 8B 24 25 A8 01 00 00    mov     rsp, gs:1A8h                    ; 切换到内核栈
   .text:0000000140411E15 6A 2B                         push    2Bh ; '+'
   .text:0000000140411E17 65 FF 34 25 10 00 00 00       push    qword ptr gs:10h
   .text:0000000140411E1F 41 53                         push    r11
   .text:0000000140411E21 6A 33                         push    33h ; '3'
   .text:0000000140411E23 51                            push    rcx
   .text:0000000140411E24 49 8B CA                      mov     rcx, r10                        ; 在Ring3 ntdll.dll中有mov r10,rcx;因为syscall时rcx被替换为KiSystemCall64，同理，内核中r10需要被保存
   .text:0000000140411E27 48 83 EC 08                   sub     rsp, 8
   .text:0000000140411E2B 55                            push    rbp
   .text:0000000140411E2C 48 81 EC 58 01 00 00          sub     rsp, 158h
   .text:0000000140411E33 48 8D AC 24 80 00 00 00       lea     rbp, [rsp+190h+var_110]
   .text:0000000140411E3B 48 89 9D C0 00 00 00          mov     [rbp+0C0h], rbx
   .text:0000000140411E42 48 89 BD C8 00 00 00          mov     [rbp+0C8h], rdi
   .text:0000000140411E49 48 89 B5 D0 00 00 00          mov     [rbp+0D0h], rsi
   .text:0000000140411E50 F6 05 FD A6 8E 00 FF          test    byte ptr cs:KeSmapEnabled, 0FFh
   .text:0000000140411E57 74 0C                         jz      short loc_140411E65
   .text:0000000140411E57
   .text:0000000140411E59 F6 85 F0 00 00 00 01          test    byte ptr [rbp+0F0h], 1
   .text:0000000140411E60 74 03                         jz      short loc_140411E65
   .text:0000000140411E60
   .text:0000000140411E62 0F 01 CB                      stac
   ```
2. 防止硬件漏洞
3. 检查是否被调试
4. 根据eax，找到SSDT或SSSDT

   ```
   .text:0000000140412184                               KiSystemServiceRepeat:                  ; CODE XREF: KiSystemCall64+BE8↓j
   .text:0000000140412184 4C 8D 15 35 F7 9E 00          lea     r10, KeServiceDescriptorTable
   .text:000000014041218B 4C 8D 1D AE A8 8E 00          lea     r11, KeServiceDescriptorTableShadow
   .text:0000000140412192 F7 43 78 80 00 00 00          test    dword ptr [rbx+78h], 80h        ; 判断是不是GDI线程
   .text:0000000140412199 74 13                         jz      short loc_1404121AE
   .text:0000000140412199
   .text:000000014041219B F7 43 78 00 00 20 00          test    dword ptr [rbx+78h], 200000h    ; 检测是否限制GUI线程
   .text:00000001404121A2 74 07                         jz      short loc_1404121AB             ; r10即ssdt或ssdts
   .text:00000001404121A2
   .text:00000001404121A4 4C 8D 1D 55 AA 8E 00          lea     r11, KeServiceDescriptorTableFilter
   .text:00000001404121A4
   .text:00000001404121AB
   .text:00000001404121AB                               loc_1404121AB:                          ; CODE XREF: KiSystemCall64+3A2↑j
   .text:00000001404121AB 4D 8B D3                      mov     r10, r11                        ; r10即ssdt或ssdts
   ```
5. 找到系统服务和参数个数

   ```
   .text:00000001404121AE                               loc_1404121AE:                          ; CODE XREF: KiSystemCall64+399↑j
   .text:00000001404121AE 41 3B 44 3A 10                cmp     eax, [r10+rdi+10h]              ; eax是调用号，ssdt+0x10处是ssdt服务个数
   .text:00000001404121B3 0F 83 F6 07 00 00             jnb     loc_1404129AF                   ; 如果在ssddt调用范围内正常执行，否则跳转
   .text:00000001404121B3
   .text:00000001404121B9 4D 8B 14 3A                   mov     r10, [r10+rdi]                  ; r10处是一个结构体，第一个字段的值才是SSDT表的地址
   .text:00000001404121BD 4D 63 1C 82                   movsxd  r11, dword ptr [r10+rax*4]      ; ssdt表每个内容占四字节，r11位对应ssdt表中内容
   .text:00000001404121C1 49 8B C3                      mov     rax, r11                        ; ssdt中存放的都是偏移，偏移的低的四字节为参数个数
   .text:00000001404121C4 49 C1 FB 04                   sar     r11, 4                          ; 实际上这部分加密过，使用时需要逻辑右移4才能得到正确的值
   .text:00000001404121C8 4D 03 D3                      add     r10, r11                        ; 将偏移与基址相加得到真正函数地址
   .text:00000001404121CB 83 FF 20                      cmp     edi, 20h ; ' '                  ; 判断是否使用ssdts
   .text:00000001404121CE 75 50                         jnz     short loc_140412220
   .text:00000001404121CE
   .text:00000001404121D0 4C 8B 9B F0 00 00 00          mov     r11, [rbx+0F0h]
   ```
6. 复制参数

   ```
   .text:0000000140412220                               loc_140412220:                          ; CODE XREF: KiSystemCall64+3CE↑j
   .text:0000000140412220                                                                       ; KiSystemCall64+3DF↑j
   .text:0000000140412220 83 E0 0F                      and     eax, 0Fh                        ; 低四位为参数个数
   .text:0000000140412223 0F 84 B7 00 00 00             jz      KiSystemServiceCopyEnd          ; 没有就不复制
   .text:0000000140412223
   .text:0000000140412229 C1 E0 03                      shl     eax, 3                          ; 以下用作分配参数
   .text:000000014041222C 48 8D 64 24 90                lea     rsp, [rsp-70h]
   .text:0000000140412231 48 8D 7C 24 18                lea     rdi, [rsp+100h+var_E8]
   .text:0000000140412236 48 8B B5 00 01 00 00          mov     rsi, [rbp+100h]
   .text:000000014041223D 48 8D 76 20                   lea     rsi, [rsi+20h]
   .text:0000000140412241 F6 85 F0 00 00 00 01          test    byte ptr [rbp+0F0h], 1
   .text:0000000140412248 74 16                         jz      short loc_140412260
   .text:0000000140412248
   .text:000000014041224A 48 3B 35 B7 FF C0 FF          cmp     rsi, cs:MmUserProbeAddress
   .text:0000000140412251 48 0F 43 35 AF FF C0 FF       cmovnb  rsi, cs:MmUserProbeAddress
   .text:0000000140412259 0F 1F 80 00 00 00 00          nop     dword ptr [rax+00000000h]
   .text:0000000140412259
   .text:0000000140412260
   .text:0000000140412260                               loc_140412260:                          ; CODE XREF: KiSystemCall64+448↑j
   .text:0000000140412260 4C 8D 1D 79 00 00 00          lea     r11, KiSystemServiceCopyEnd
   .text:0000000140412267 4C 2B D8                      sub     r11, rax                        ; 减去偏移，得到复制地址
   .text:000000014041226A 41 FF E3                      jmp     r11                             ; 跳转复制
   .text:000000014041226A
   .text:000000014041226A                               ; ---------------------------------------------------------------------------
   .text:000000014041226D CC CC CC                      align 10h
   .text:0000000140412270
   .text:0000000140412270                               KiSystemServiceCopyStart:               ; DATA XREF: KiSystemServiceHandler+1A↑o
   .text:0000000140412270 48 8B 46 70                   mov     rax, [rsi+70h]
   .text:0000000140412274 48 89 47 70                   mov     [rdi+70h], rax
   .text:0000000140412278 48 8B 46 68                   mov     rax, [rsi+68h]
   .text:000000014041227C 48 89 47 68                   mov     [rdi+68h], rax
   .text:0000000140412280 48 8B 46 60                   mov     rax, [rsi+60h]
   .text:0000000140412284 48 89 47 60                   mov     [rdi+60h], rax
   .text:0000000140412288 48 8B 46 58                   mov     rax, [rsi+58h]
   .text:000000014041228C 48 89 47 58                   mov     [rdi+58h], rax
   .text:0000000140412290 48 8B 46 50                   mov     rax, [rsi+50h]
   .text:0000000140412294 48 89 47 50                   mov     [rdi+50h], rax
   .text:0000000140412298 48 8B 46 48                   mov     rax, [rsi+48h]
   .text:000000014041229C 48 89 47 48                   mov     [rdi+48h], rax
   .text:00000001404122A0 48 8B 46 40                   mov     rax, [rsi+40h]
   .text:00000001404122A4 48 89 47 40                   mov     [rdi+40h], rax
   .text:00000001404122A8 48 8B 46 38                   mov     rax, [rsi+38h]
   .text:00000001404122AC 48 89 47 38                   mov     [rdi+38h], rax
   .text:00000001404122B0 48 8B 46 30                   mov     rax, [rsi+30h]
   .text:00000001404122B4 48 89 47 30                   mov     [rdi+30h], rax
   .text:00000001404122B8 48 8B 46 28                   mov     rax, [rsi+28h]
   .text:00000001404122BC 48 89 47 28                   mov     [rdi+28h], rax
   .text:00000001404122C0 48 8B 46 20                   mov     rax, [rsi+20h]
   .text:00000001404122C4 48 89 47 20                   mov     [rdi+20h], rax
   .text:00000001404122C8 48 8B 46 18                   mov     rax, [rsi+18h]
   .text:00000001404122CC 48 89 47 18                   mov     [rdi+18h], rax
   .text:00000001404122D0 48 8B 46 10                   mov     rax, [rsi+10h]
   .text:00000001404122D4 48 89 47 10                   mov     [rdi+10h], rax
   .text:00000001404122D8 48 8B 46 08                   mov     rax, [rsi+8]
   .text:00000001404122DC 48 89 47 08                   mov     [rdi+8], rax
   .text:00000001404122DC
   .text:00000001404122E0
   .text:00000001404122E0                               KiSystemServiceCopyEnd:                 ; CODE XREF: KiSystemCall64+423↑j
   ```
7. 跳转到系统服务函数地址

   ```
   text:00000001404122E0                                                                       ; DATA XREF: KiSystemServiceHandler+27↑o
   .text:00000001404122E0                                                                       ; KiSystemCall64:loc_140412260↑o
   .text:00000001404122E0 F7 05 16 A3 8E 00 01 00 00 00 test    cs:KiDynamicTraceMask, 1
   .text:00000001404122EA 0F 85 5D 07 00 00             jnz     loc_140412A4D
   .text:00000001404122EA
   .text:00000001404122F0 F7 05 8E A1 8E 00 40 00 00 00 test    dword ptr cs:PerfGlobalGroupMask+8, 40h
   .text:00000001404122FA 0F 85 C1 07 00 00             jnz     loc_140412AC1
   .text:00000001404122FA
   .text:0000000140412300 49 8B C2                      mov     rax, r10
   .text:0000000140412303 FF D0                         call    rax                             ; 跳转到对应地址
   ```
8. 执行用户APC
9. Sysret返回

   ```
   .text:0000000140412656                               loc_140412656:                          ; CODE XREF: KiSystemCall64+848↑j
   .text:0000000140412656 48 8B 45 B0                   mov     rax, [rbp-50h]
   .text:000000014041265A 4C 8B 85 00 01 00 00          mov     r8, [rbp+100h]
   .text:0000000140412661 4C 8B 8D D8 00 00 00          mov     r9, [rbp+0D8h]
   .text:0000000140412668 33 D2                         xor     edx, edx
   .text:000000014041266A 66 0F EF C0                   pxor    xmm0, xmm0
   .text:000000014041266E 66 0F EF C9                   pxor    xmm1, xmm1
   .text:0000000140412672 66 0F EF D2                   pxor    xmm2, xmm2
   .text:0000000140412676 66 0F EF DB                   pxor    xmm3, xmm3
   .text:000000014041267A 66 0F EF E4                   pxor    xmm4, xmm4
   .text:000000014041267E 66 0F EF ED                   pxor    xmm5, xmm5
   .text:0000000140412682 48 8B 8D E8 00 00 00          mov     rcx, [rbp+0E8h]
   .text:0000000140412689 4C 8B 9D F8 00 00 00          mov     r11, [rbp+0F8h]
   .text:0000000140412690 F6 05 A9 F1 9E 00 01          test    cs:KiKvaShadow, 1
   .text:0000000140412697 0F 85 23 67 60 00             jnz     KiKernelSysretExit
   .text:0000000140412697
   .text:000000014041269D 49 8B E9                      mov     rbp, r9
   .text:00000001404126A0 49 8B E0                      mov     rsp, r8
   .text:00000001404126A3 66 65 F7 04 25 60 08 00 00 00+test    word ptr gs:860h, 100h
   .text:00000001404126A3 01
   .text:00000001404126AE 74 09                         jz      short loc_1404126B9
   .text:00000001404126AE
   .text:00000001404126B0 65 0F 00 2C 25 2A 90 00 00    verw    word ptr gs:902Ah
   .text:00000001404126B0
   .text:00000001404126B9
   .text:00000001404126B9                               loc_1404126B9:                          ; CODE XREF: KiSystemCall64+8AE↑j
   .text:00000001404126B9 0F 01 F8                      swapgs
   .text:00000001404126BC 48 0F 07                      sysret
   ```

##### 定位SSDT

System Services Descriptor Table 系统服务描述表

KeServiceDescriptorTable是内核中一个未导出的变量，实际上是一个结构体

```
typedef struct ServiceDescriptorTable {
	PVOID ServiceTableBase;
	PVOID ServiceCounterTable(0);
	unsigned int NumberOfServices;
	PVOID ParamTableBase;
};
```

* ServiceTableBase :System Service Dispatch Table 的基地址。
* ServiceCounterTable 此域用于操作系统的 checked builds，包含着 SSDT 中每个服务被调用次数的计数器。这个计数器由 INT 2Eh 处理程序 (KiSystemService)更新
* NumberOfServices 由 ServiceTableBase 描述的服务的数目。
* ParamTableBase 包含每个系统服务参数字节数表的基地址。

所以要找SSDT表的基地址要找KeServiceDescriptorTable的地址，而在KiSystemServiceRepeat函数中有如下代码

```
nt!KiSystemServiceRepeat:
fffff806`5dc12184 4c8d1535f79e00     lea     r10, [ntkrnlmp!KeServiceDescriptorTable (fffff8065e6018c0)]
fffff806`5dc1218b 4c8d1daea88e00     lea     r11, [ntkrnlmp!KeServiceDescriptorTableShadow (fffff8065e4fca40)]
fffff806`5dc12192 f7437880000000     test    dword ptr [rbx+78h], 80h
```

也就是说找到KiSystemServiceRepeat中第一条指令地址就读取到了相对于KeServiceDescriptorTable所在地址的偏移，如何找到KiSystemServiceRepeat函数地址

关于sysenter指令和syscall指令

```
sysenter 和 syscall 指令都用于高效地实现从用户态到内核态的切换

sysenter 指令：
功能：
1. sysenter 指令用于在 IA-32e 模式（64 位长模式）下进行系统调用。
2. 这个指令用于从用户空间切换到内核空间，执行内核提供的服务例程。
使用：
1. 在使用 sysenter 指令之前，需要设置 IA32_SYSENTER_CS、IA32_SYSENTER_ESP 和 IA32_SYSENTER_EIP 这三个 MSR 寄存器来指定内核代码段选择子、内核栈指针和系统调用入口地址。
2. 用户空间调用 sysenter 指令，CPU 就会根据设置好的 MSR 寄存器的值跳转到内核的系统调用入口地址执行相应的服务例程。

syscall 指令：
功能：
1.syscall 指令用于在长模式（64 位）下进行系统调用。
2. 与 sysenter 不同，syscall 是在 64 位模式下使用的系统调用指令。
使用：
1. 使用 syscall 指令之前，需要设置 IA32_LSTAR MSR 寄存器，其中存储了系统调用的入口地址。
2. 在用户空间调用 syscall 指令时，CPU 会根据 IA32_LSTAR 寄存器中的值跳转到内核的系统调用入口地址执行相应的服务例程。

syscall 通常用于 x86-64 架构，而 sysenter 主要用于 x86 架构
```

通过msr寄存器来找，在Intel白皮书中第四卷第二章TABLE 2-2

```
174H    IA32_SYSENTER_CS    SYSENTER_CS_MSR (R/W) 06_01H

175H    IA32_SYSENTER_ESP    SYSENTER_ESP_MSR (R/W) 06_01H
176H    IA32_SYSENTER_EIP SYSENTER_EIP_MSR (R/W) 06_01H

C0000082H    IA32_LSTAR    IA-32e Mode System Call Target Address (R/W) Target RIP for the called procedure when SYSCALL is executed in 64-bit mode.
If  CPUID.80000001:EDX.[29] = 1
```

msr的0xC0000082处存放系统调用的入口地址，sysenter从MSR的找到IA32_SYSENTER_EIP是KiFastCallEntry，而syscall则是从IA32_LSTAR找到入口函数
在开启内核隔离模式下获取的是 KiSystemCall64Shadow ，而在未开启内核模式下则是获取的 KiSystemCall64

KiSystemCall64 KiSystemCall64Shadow在内核中有一个固定偏移，通过winDbg或IDA反汇编找到与KiSystemServiceRepeat的偏移为offset，这样就找到了KeServiceDescriptorTable的地址，也就找到SSDT表的地址了

未开启内核隔离模式下，KiSystemCall64之后就是KiSystemServiceRepeat等函数，由于lea r10这个操作在这段代码中只有一处，所以可以从KiSystemCall64开始枚举 `lea r10`的opcode来找到 `lea     r10, KeServiceDescriptorTable`的地址，进而获取偏移

```
0x4c 0x8d 0x15  lea r10---> Get SSDT
0x4c 0x8d 0x1d  lea r11---> Get SSDTShadow
```

开启内核隔离的模式下，由于KiSystemCall64Shadow位于较高地址空间处还需要通过先获取偏移找到较低地址空间作为参考函数再开始枚举

以未开启内核隔离的模式为例，获取SSDT并枚举

```
#include <ntifs.h>
#include <crt/intrin.h>
#pragma intrinsic(__readmsr)

struct ServiceDescriptorTable {
	PVOID ServiceTableBase;
	PVOID ServiceCounterTable;
	unsigned int NumberOfServices;
	PVOID ParamTableBase;
};

// 获取KeServiceDescriptorTable地址
ULONGLONG GetKeServiceDescriptorTable()
{

	PUCHAR StartSearchAddress = (PUCHAR)__readmsr(0xC0000082);
	PUCHAR EndSearchAddress = StartSearchAddress + 0xD18;
	DbgPrint("扫描起始地址: %p --> 扫描结束地址: %p \n", StartSearchAddress, EndSearchAddress);

	PUCHAR ByteCode;
	PUCHAR OpCodeA = 0, OpCodeB = 0, OpCodeC = 0;
	ULONGLONG addr = 0;
	ULONG templong = 0;

	for (ByteCode = StartSearchAddress; ByteCode < EndSearchAddress; ByteCode++)
	{
		if (MmIsAddressValid(ByteCode) && MmIsAddressValid(ByteCode + 1) && MmIsAddressValid(ByteCode + 2))
		{
			if (*ByteCode == 0x4C && *(ByteCode + 1) == 0x8D && *(ByteCode + 2) == 0x15)
			{
				memcpy(&templong, ByteCode+3, 4);
				addr = (ULONGLONG)templong + (ULONGLONG)ByteCode + 0x7;
				return addr;
			}
		}
	}

	return 0;
}

//枚举SSDT
void EnumSSDT(ULONGLONG ssdt_address)
{
	PVOID funcaddr;
	ULONG offset;
	PULONG ssdt = (PULONG)((ServiceDescriptorTable*)ssdt_address)->ServiceTableBase;
	unsigned int num = ((ServiceDescriptorTable*)ssdt_address)->NumberOfServices;
	//DbgBreakPoint();
	for (unsigned int i = 0; i < num; i++)
	{
		offset = *(ssdt + i);
		offset = offset >> 4;
		funcaddr = ((PUCHAR)ssdt + offset);
		DbgPrint("%u 号系统调用所在地址：0x%p\n", i, funcaddr);
	}
}

void UnDriver(PDRIVER_OBJECT pDriver)
{
	DbgPrint(("驱动程序卸载成功! \n"));
}

NTSTATUS DriverEntry(PDRIVER_OBJECT pDriver,PUNICODE_STRING RegistryPath)
{
	DbgPrint("hello lyshark.com \n");
	ULONGLONG ssdt_address = GetKeServiceDescriptorTable();
	DbgPrint("SSDT基地址 = %p \n", ssdt_address);
	if (ssdt_address != 0) {
		EnumSSDT(ssdt_address);
	}

	pDriver->DriverUnload = UnDriver;
	DbgPrint(("驱动程序加载成功! \n"));
	return STATUS_SUCCESS;
}
```

##### 枚举SSDT Shadow

过程同枚举SSDT类似，但是由于系统调用是从0x1000开始的，而W32pServiceTable从0偏移处就存放数据了，所以实际上的系统调用号减0x1000才是函数在W32pServiceTable中的对应偏移

枚举W32pServiceTable时必须要在GUI线程中执行，否则会异常， 建议将枚举过程写成DLL文件，注入到explorer.exe进程内执行

```
#include <ntifs.h>
#include <crt/intrin.h>
#pragma intrinsic(__readmsr)

struct ServiceDescriptorTable {
	PVOID ServiceTableBase;
	PVOID ServiceCounterTable;
	unsigned int NumberOfServices;
	PVOID ParamTableBase;
};

// 获取KeServiceDescriptorTableShadow地址
ULONGLONG GetKeServiceDescriptorTableShadow()
{

	PUCHAR StartSearchAddress = (PUCHAR)__readmsr(0xC0000082);
	PUCHAR EndSearchAddress = StartSearchAddress + 0xD18;
	DbgPrint("扫描起始地址: %p --> 扫描结束地址: %p \n", StartSearchAddress, EndSearchAddress);

	PUCHAR ByteCode;
	PUCHAR OpCodeA = 0, OpCodeB = 0, OpCodeC = 0;
	ULONGLONG addr = 0;
	ULONG templong = 0;

	for (ByteCode = StartSearchAddress; ByteCode < EndSearchAddress; ByteCode++)
	{
		if (MmIsAddressValid(ByteCode) && MmIsAddressValid(ByteCode + 1) && MmIsAddressValid(ByteCode + 2))
		{
			if (*ByteCode == 0x4C && *(ByteCode + 1) == 0x8D && *(ByteCode + 2) == 0x1D)
			{
				memcpy(&templong, ByteCode + 3, 4);
				addr = (ULONGLONG)templong + (ULONGLONG)ByteCode + 0x7;
				return addr;
			}
		}
	}

	return 0;
}

//枚举SSDT
void EnumSSDT(ULONGLONG ssdts_address)
{
	ServiceDescriptorTable* addr = (ServiceDescriptorTable*)((PUCHAR)ssdts_address + 0x20);
	PULONG W32pSt = (PULONG)(addr->ServiceTableBase);
	unsigned int NumOfServices = addr->NumberOfServices;

	ULONG offset;
	PVOID funcaddr;
	//DbgBreakPoint();

	for (unsigned int i = 0x1000; i < (0x1000 + NumOfServices); i++)
	{
		offset = *(W32pSt + i-0x1000);
		offset = offset >> 4;
		funcaddr = ((PUCHAR)(W32pSt)+offset);
		DbgPrint("0x%x 号系统调用所在地址：0x%p\n", i, funcaddr);
	}

}

PVOID GetW32pServiceTable(ULONGLONG ssdts_address)
{
	ServiceDescriptorTable* addr = (ServiceDescriptorTable*)((PUCHAR)ssdts_address + 0x20);
	return (PVOID)(addr->ServiceTableBase);
}

void UnDriver(PDRIVER_OBJECT pDriver)
{
	DbgPrint(("驱动程序卸载成功! \n"));
}

NTSTATUS DriverEntry(PDRIVER_OBJECT pDriver, PUNICODE_STRING RegistryPath)
{
	DbgPrint("hello lyshark.com \n");
	ULONGLONG ssdts_address = GetKeServiceDescriptorTableShadow();
	PVOID W32pSt = GetW32pServiceTable(ssdts_address);
	DbgPrint("W32pServiceTable基地址 = %p \n", W32pSt);
	if (W32pSt != 0) {
		EnumSSDT(ssdts_address);
	}

	pDriver->DriverUnload = UnDriver;
	DbgPrint(("驱动程序加载成功! \n"));
	return STATUS_SUCCESS;
}
```

#### IRQL

中断分为外部中断和内部中断

外部中断即硬件中断，如键盘中断、打印机中断、定时器中断

内部中断是由int n产生的中断

Windows 将中断进行的扩展，提出一个中断请求级（IQRL）的概念。其中规定了 32个中断请求级别，分别是 0-2 级别为软件中断，3-31 为硬件中断。

Windows IRQL的宏定义

```
#define PASSIVE_LEVEL 0                               // Passive release level
#define LOW_LEVEL 0                                      // Lowest interrupt level
#define APC_LEVEL 1                                       // APC interrupt level
#define DISPATCH_LEVEL 2                            // Dispatcher level
#define CMCI_LEVEL 5                                     // CMCI handler level
#define PROFILE_LEVEL 27                             // timer used for profiling.
#define CLOCK1_LEVEL 28                              // Interval clock 1 level - Not used on x86
#define CLOCK2_LEVEL 28                              // Interval clock 2 level
#define IPI_LEVEL 29                                        // Interprocessor interrupt level
#define POWER_LEVEL 30                               // Power failure level
#define HIGH_LEVEL 31                                    // Highest interrupt level
#define CLOCK_LEVEL (CLOCK2_LEVEL)
```

常见的IRQL级别有四个：Passive、APC、 Dispatch、DIRQL。

* PASSIVE_LEVEL：IRQL最低级别，没有被屏蔽的中断，线程执行用户模式，可以访问分页内存。
* APC_LEVEL：只有APC级别的中断被屏蔽，可以访问分页内存。当有APC发生时，处理器提升到APC级别，这样，就屏蔽掉其它APC，为了和APC执行 一些同步，驱动程序可以手动提升到这个级别。比如，如果提升到这个级别，APC就不能调用。在这个级别，APC被禁止了，导致禁止一些I/O完成APC， 所以有一些API不能调用。
* DISPATCH_LEVEL：DPC(延迟过程) 和更低的中断被屏蔽，不能访问分页内存，所有的被访问的内存不能分页。因为只能处理分页内存，所以在这个级别，能够访问的API大大减少。
* DIRQL (Device IRQL)：通常处于高层次的驱动程序不会使用这个IRQL等级，在这个等级上所有的中断都会被忽略。这是IRQL的最高等级，通常使用这个来判断设备的优先级。

当 IRQL 提升到 DISPATCH_LEVEL 申请分页内存，导致系统蓝屏

错误码：IRQL_NOT_LESS_OR_EQUAL

蓝屏原因：缺页中断机制是运行在 DISPATCH_LEVEL 级别下的，和当前代码处于一个级别，当代码访问到一个内存页在换页文件的时候，缺页机制无法打断当前代码的运行，从而无法进行页交换，导致访问到了一个错误的内存地址，进而蓝屏。

##### IRQL API

###### KeRaiseIrql

```
VOID KeRaiseIrql(
  _In_  KIRQL  NewIrql,
  _Out_ PKIRQL OldIrql
);
```

* `[in] a`：NewIrql 参数指定要将硬件优先级提升到的新 KIRQL 值
* `[out] b`：OldIrql 参数是指向原始 (未) KIRQL 值的存储的指针，将在后续调用 [KeLowerIrql](https://learn.microsoft.com/zh-cn/windows-hardware/drivers/ddi/wdm/nf-wdm-kelowerirql) 时使用

###### KeLowerIrql

```
void KeLowerIrql(
  [in] KIRQL NewIrql
);
```

* `[in] NewIrql`：指定从 KeRaiseIrql 或 [KeRaiseIrqlToDpcLevel 返回的 IRQL](https://learn.microsoft.com/zh-cn/windows-hardware/drivers/ddi/wdm/nf-wdm-keraiseirqltodpclevel)。

###### KeGetCurrentIrql

```
NTHALAPI KIRQL KeGetCurrentIrql();
```

返回当前 IRQL。

[windows内核开发笔记十一：IRQL级别调用说明_windows驱动 irql级别](https://blog.csdn.net/jyl_sh/article/details/115079506)

[IRQL的理解和认识](https://blog.csdn.net/qq_42021840/article/details/106113416)

#### 内核读写

##### 切换CR寄存器读写内存

###### CR寄存器

[控制寄存器 cr0,cr2,cr3 - chingliuyu - 博客园](https://www.cnblogs.com/chingliu/archive/2011/08/28/2223804.html)

CR0：含有含有控制处理器操作模式的和状态的系统控制标志

CR1：保留不用

CR2：含有导致页错误的线性地址

CR3：含有页目录表物理内存基地址，也称PDBR（Page Table Base Register，页表基址寄存器）

###### 具体流程

以读为例：通过API函数获得对应进程的PEPROCESS结构体，PEPROCESS+0x28处存放了对应进程页目录表的地址，通过此来改写cr3寄存器值为对应进程的页目录表，读取对应进程的内存内容，将cr3寄存器改回原来的内容

在读写用户内存空间时（即 `0x0000ffff ffffffff`之前），需要将cr3寄存器的值改为对应进程的页目录表，并在此期间禁用中断避免异常，完成读写后，恢复cr3寄存器以及启用中断

##### MDL

#### 内核枚举

##### 枚举线程与进程

枚举进程使用之前的API获取PEPROCESS结构体来枚举

枚举线程则通过PsLookupThreadByThreadId来获取对应tid的ETHREAD结构体，使用IoThreadToProcess获取ETHREAD所属的PEPROCESS结构体如果和指定PID的PEPROCESS相同说明为该进程的线程

##### 枚举内核DLL


#### 内核回调
