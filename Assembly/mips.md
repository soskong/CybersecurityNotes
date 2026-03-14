#### 寄存器

| 寄存器编号 |  寄存器名  | 寄存器用途                                                                         |
| :--------: | :---------: | ---------------------------------------------------------------------------------- |
|     0     |    zero    | 永远为0                                                                            |
|     1     |   `$at`   | Assembly Temporary，汇编保留寄存器，手写汇编时原则上不要用，除非明确 `.set noat` |
|    2-3    |  `v0-v1`  | caller-saved，v0为主要返回值，v1为64位返回值的高32位                               |
|    4-7    |  `a0-a3`  | caller-saved，存储子程序的前4个参数，其余通过栈传递                                |
|    8-15    |  `t0-t7`  | caller-saved，调用者保存函数可以随便用，不负责恢复                                 |
|   16-23   |  `s0-s7`  | callee-saved，如果函数用到了，必须在返回前恢复                                     |
|   24-25   |  `t8-t9`  | caller-saved，同上 `t0-t7`，t9常被用做保存被调用函数入口地址                     |
|   26-27   |  `k0-k1`  | 仅内核 / 异常 / 中断使用                                                           |
|     28     |   `$gp`   | 指向数据段（64KB）的中间，通过±2¹⁵，高效访问                                    |
|     29     |   `$sp`   | 栈指针，指向栈顶                                                                   |
|     30     | `$s8/$fp` | callee-saved，(Frame Pointer)栈帧指针，开启优化时不用                              |
|     31     |   `$ra`   | caller-saved，函数调用返回地址                                                     |

caller-saved（调用者保存）寄存器：被调用函数可以随意覆盖，返回时不保证值还在

callee-saved（被调用者保存）寄存器：如果函数用到了，必须在返回前恢复

#### 汇编指令

加载保存指令

```
load 内存->寄存器	register_destination = RAM_source
l[b/h/w/d/] register_destination, RAM_source：load 1/2/4/8byte
li register_destination, value：加载立即数
store 寄存器->内存 	RAM_destination = register_source
s[b/h/w/d/] register_source, RAM_destination：store 1/2/4/8byte

寻址
la $to,var1：$to=var1
```

跳转

```
通过b类型指令跳转常用于分支判断，通过j*al类型的跳转通常是函数调用跳转，要将返回地址存入$ra中

J	绝对跳转
JR	寄存器绝对跳转，寻址空间大于256M，一般用于函数返回的跳转
JAL	函数调用，需要将返回地址保存到$ra
JALR	寄存器函数调用，寻址空间大于256M，需要将返回地址保存到$ra，通常是JALR $t9

不带寄存器的J和JAL指令，通过特定方式确定偏移，固定操作码为10 0C，而且偏移时针对当前$pc位置的
```

运算 

[MIPS指令集：运算指令、访存指令、分支和跳转、协处理器0指令-CSDN博客](https://blog.csdn.net/weixin_38669561/article/details/104445763)

#### 函数调用

函数调用前

```
.text:00400F90 E0 FF BD 27                   addiu   $sp, -0x20				// 扩展0x20字节
.text:00400F94 1C 00 BF AF                   sw      $ra, 0x18+var_s4($sp)		// 实际上，新栈的后0x8字节用来
.text:00400F98 18 00 BE AF                   sw      $fp, 0x18+var_s0($sp)		// 保存栈基址寄存器$fp和返回地址$ra，各0x4byte
.text:00400F9C 25 F0 A0 03                   move    $fp, $sp				// 将调用新函数，将栈基址上移
.text:00400FA0 42 00 1C 3C E0 94 9C 27       li      $gp, (_GLOBAL_OFFSET_TABLE_+0x7FF0)// 正确设置数据段基址寄存器$gp的值
.text:00400FA8 10 00 BC AF                   sw      $gp, 0x18+var_8($sp)		// 保存在之前0x8字节之上的0x4byte
.text:00400FAC 40 00 02 3C                   lui     $v0, 0x40  # '@'			// 使用临时寄存器$v0
.text:00400FB0 BC 13 44 24                   addiu   $a0, $v0, (aWriteDownYourF - 0x400000)  # "Write down your feeling:" // 传参给$a0
.text:00400FB4 70 80 82 8F                   la      $v0, puts				// 使用临时寄存器给$t9赋值
.text:00400FB8 25 C8 40 00                   move    $t9, $v0
.text:00400FBC 09 F8 20 03                   jalr    $t9 ; puts
.text:00400FC0 00 00 00 00                   nop					// 一般跳转后都有nop
.text:00400FC0
.text:00400FC4 10 00 DC 8F                   lw      $gp, 0x18+var_8($fp)		// 函数调用完恢复$gp的值
.text:00400FC8 CD 03 10 0C                   jal     vul				// 调用vuln函数
.text:00400FCC 00 00 00 00                   nop
.text:00400FCC
.text:00400FD0 10 00 DC 8F                   lw      $gp, 0x18+var_8($fp)		// 函数调用完恢复$gp的值
.text:00400FD4 00 00 00 00                   nop
.text:00400FD8 25 E8 C0 03                   move    $sp, $fp				// 清除新栈
.text:00400FDC 1C 00 BF 8F                   lw      $ra, 0x18+var_s4($sp)		// 恢复$ra
.text:00400FE0 18 00 BE 8F                   lw      $fp, 0x18+var_s0($sp)		// 恢复$fp
.text:00400FE4 20 00 BD 27                   addiu   $sp, 0x20				// 清除新栈
.text:00400FE8 08 00 E0 03                   jr      $ra				// 返回
.text:00400FEC 00 00 00 00                   nop
```

常见形式如

```
.text:00400F34 A8 FF BD 27                   addiu   $sp, -0x58				// 扩栈
.text:00400F38 54 00 BF AF                   sw      $ra, 0x50+var_s4($sp)		// 存 $fp 和 $ra
.text:00400F3C 50 00 BE AF                   sw      $fp, 0x50+var_s0($sp)
.text:00400F40 25 F0 A0 03                   move    $fp, $sp				// 清除旧栈
.text:00400F44 42 00 1C 3C E0 94 9C 27       li      $gp, (_GLOBAL_OFFSET_TABLE_+0x7FF0)
.text:00400F4C 10 00 BC AF                   sw      $gp, 0x50+var_40($sp)		// 设置$gp
.text:00400F50 B0 00 06 24                   li      $a2, 0xB0                        # nbytes
.text:00400F54 18 00 C2 27                   addiu   $v0, $fp, 0x50+var_38
.text:00400F58 25 28 40 00                   move    $a1, $v0                         # buf
.text:00400F5C 25 20 00 00                   move    $a0, $zero                       # fd	// 传参
.text:00400F60 5C 80 82 8F                   la      $v0, read				// 给$t9赋值
.text:00400F64 25 C8 40 00                   move    $t9, $v0
.text:00400F68 09 F8 20 03                   jalr    $t9 ; read				// 调用
.text:00400F6C 00 00 00 00                   nop
.text:00400F6C
.text:00400F70 10 00 DC 8F                   lw      $gp, 0x50+var_40($fp)		// 恢复 $gp
.text:00400F74 00 00 00 00                   nop
.text:00400F78 25 E8 C0 03                   move    $sp, $fp				// 恢复 $sp
.text:00400F7C 54 00 BF 8F                   lw      $ra, 0x50+var_s4($sp)
.text:00400F80 50 00 BE 8F                   lw      $fp, 0x50+var_s0($sp)
.text:00400F84 58 00 BD 27                   addiu   $sp, 0x58
.text:00400F88 08 00 E0 03                   jr      $ra
.text:00400F8C 00 00 00 00                   nop
```
