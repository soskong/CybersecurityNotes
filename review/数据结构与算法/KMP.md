第一次仅把思想看了个大概就上手，遇到的问题

1. 所谓的最长相等前后缀是超越中心点的，即aaaaa的对应的值为4
2. 第一次使用了暴力求解next数组，世界上可以回溯j实现更高效的算法
3. 在进行匹配时，回溯的是主串，实际上回溯模式串更高效

修正后

```
int strStr(char* haystack, char* needle) {

	int n = strlen(haystack), m = strlen(needle);

	if (m == 0) {
		return 0;
	}
	int* pi = (int*)malloc(4 * m);

	pi[0] = 0;

	// 关键在于动态添加，0-i的最长前后缀存在时，如果新添加的字符和之前的后缀的后一个字母相同，则next对应位置+1

	for (int i = 1, j = 0; i < m; i++) {
		while (j > 0 && needle[i] != needle[j]) {
			// 当新添加的i处与j处不同时，
			// 可以发现之前的串与j之前的串都一样，就这个不一样，而j之前的串的字串（即前缀处）也有这样的效果
			// 回退到j前字串的前缀处，再比较新添加的字符是否满足
			j = pi[j - 1];
		}

		// 相同则继续移动前缀指针
		if (needle[i] == needle[j]) {
			j++;
		}

		pi[i] = j;	// next数组赋值
	}

	for (int i = 0, j = 0; i < n; i++) {
		while (j > 0 && haystack[i] != needle[j]) {
			j = pi[j - 1];	// 回退模式串指针
		}
		if (haystack[i] == needle[j]) {
			j++;
		}
		if (j == m) {
			return i - m + 1;
		}
	}

	return -1;
}
```
