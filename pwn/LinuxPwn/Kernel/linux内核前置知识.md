### 内核保护

#### SMEP

Supervisor Mode Execution Protection，用户代码不可执行，CR4 寄存器中的第 20 位用来标记是否开启 SMEP 保护

默认情况下，SMEP 保护是开启的

把 CR4 寄存器中的第 20 位置为 0 后，我们就可以执行用户态的代码，一般设置为0x6f0

当我们能够劫持控制流后，我们可以执行内核中的 gadget 来修改 CR4，内核中存在固定的修改 cr4 的代码，比如在 `refresh_pce` 函数、`set_tsc_mode` 等函数里都有

#### SMAP

Supervisor Mode Access Protection，用户数据不可访问，

#### KPTI

Kernel Page Table Isolation，内核页表隔离

* 内核态中的页表包括用户空间内存的页表和内核空间内存的页表
* 用户态的页表只包括用户空间内存的页表以及必要的内核空间内存的页表，如用于处理系统调用、中断等信息的内存
* 用户态空间的所有数据都被标记了 NX 权限（附带加固）

KPTI可以防止meltdown

meltdown，将内核中的数据加载到内存时，先会将其加载到cache，装入内存时触发保护，实际上在微架构层面已经存在了内核数据，通过测信道攻击可以读取内核数据

开启KPTI后，内核关键数据直接无法访问，避免了meltdown

#### KASLR

在开启了 KASLR 的内核中，内核的代码段基地址等地址会整体偏移

### 内核函数

1. alloc_chrdev_region

   ```
   int alloc_chrdev_region(dev_t *dev, unsigned baseminor, unsigned count, const char *name);
   功能
   动态分配一个未被使用的主设备号，避免与系统中已注册的设备号冲突，与静态分配（register_chrdev_region()）相对应
   参数
   dev_t *dev（输出参数）：指向dev_t类型变量的指针，用于接收分配到的主设备号
   unsigned baseminor（起始次设备号）：请求的起始次设备号
   unsigned count（设备数量）：需要连续分配的设备数量
   const char *name（设备名称）：设备名称，会在/proc/devices中显示
   返回值
   成功：返回0	失败：返回负的错误码
   ```
2. cdev_init

   ```
   void cdev_init(struct cdev *cdev, const struct file_operations *fops);
   功能
   初始化字符设备结构体，建立设备与操作的关联，设置默认值
   参数
   struct cdev *cdev：字符设备结构体的指针，全局变量，这个结构体将由内核维护，代表一个字符设备
   const struct file_operations *fops：文件操作结构体的指针，全局变量，包含了一系列函数指针，定义了设备的各种操作

   ```
3. cdev_add

   ```
   int cdev_add(struct cdev *p, dev_t dev, unsigned count);
   功能
   向内核注册字符设备，使设备对用户空间可见，建立设备号与驱动程序的映射
   参数
   struct cdev *p：字符设备结构体的指针，已经通过cdev_init()初始化的设备对象
   dev_t dev：起始设备号，包含主设备号和起始次设备号
   unsigned count：连续设备号的数量，在代码中：1LL（只添加1个设备），如果大于1，会注册从dev开始的count个连续设备号



   ```
4. class_create

   ```
   _class_create(&_this_module, "babydev", &babydev_no);
   功能

   参数
   struct module *owner：指定类所属的内核模块
   const char *babydev：在/sys/class/目录下创建babydev目录
   dev_t *


   ```

### linux设备

在Linux系统中，每个设备都通过一个**设备号**来标识，设备号由两部分组成：设备号 = 主设备号（12位） + 次设备号（20位）

#### 结构体

cdev

```
struct cdev {
    struct kobject kobj;                   // 内核对象，用于引用计数
    struct module *owner;                  // 所属模块（后面会设置）
    const struct file_operations *ops;     // 文件操作函数指针
    struct list_head list;                 // 链表，用于管理多个设备
    dev_t dev;                            // 设备号
    unsigned int count;                   // 设备数量
};
```

file_operations

```
struct file_operations {
    struct module *owner;
    loff_t (*llseek) (struct file *, loff_t, int);
    ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
    ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
    int (*open) (struct inode *, struct file *);
    int (*release) (struct inode *, struct file *);
    // ... 其他函数指针
};
```

Linux内核维护了一个**哈希表**来管理设备号到驱动程序的映射

```
static struct kobj_map *cdev_map;  // 全局字符设备映射表

struct kobj_map {
    struct probe {
        struct probe *next;      // 链表下一个
        dev_t dev;               // 设备号
        unsigned long range;     // 设备号范围
        struct module *owner;    // 所属模块
        kobj_probe_t *get;       // 探测函数
        int (*lock)(dev_t, void*); // 锁函数
        void *data;              // 实际指向 struct cdev *
    } *probes[255];              // 哈希桶数组
};
```
