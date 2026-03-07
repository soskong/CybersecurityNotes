```
int main(int argc,char *argv[],char *env[])
```

* **argc** ：整型，命令行参数的总个数（包含程序名，最小值为 1）。
* **argv** ：字符串数组，存储命令行参数（`argv[0]` 是程序名，`argv[argc] = NULL`）。
* **env[]** ：非标准扩展参数，存储系统环境变量（格式 `KEY=VALUE`，最后一个元素为 `NULL`）。
