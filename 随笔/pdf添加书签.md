#### PdgCntEditor & FreePic2Pdf

PdgCntEditor用于提取pdf目录，使用FreePic2Pdf添加书签

#### 步骤

1. 使用PdgCntEditor将目录信息提取

   ```
   将页目录文本复制到文本编辑器中，将页标题和页号中的点号去除，依次点击，选中区域自动缩进、自动切分页码，制作好将导入的文本文件
   ```
2. 使用FreePic2Pdf，更改pdf，从pdf中取书签，创建存放接口的文件夹
3. 将生成好的文本文件复制到接口文件夹下的 `FreePic2Pdf_bkmk.txt`文件
4. 往pdf中挂书签，编辑接口文件，更改基准页数，基准页数即正文开始的一页在pdf文件中的页数

#### 参考

[一键生成PDF文档的书签和目录(书签，目录页带页码 都行)_cjfw-CSDN博客](https://blog.csdn.net/qq_20597149/article/details/103518748)

[批量快速制作PDF书签 - 知乎](https://zhuanlan.zhihu.com/p/91455504)

##### 工具

[FreePic2Pdf.7z - 蓝奏云](https://www.lanzoui.com/it4x6j4hbvc)

[PdgCntEditor.exe - 蓝奏云](https://cloudshare.lanzouw.com/ijZPj03tmnle)
