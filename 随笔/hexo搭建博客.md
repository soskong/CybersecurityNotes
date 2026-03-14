#### 环境配置

1. 配置github免密登录，创建github仓库，仓库名必须为[username].github.io
2. 安装nodejs
3. 安装hexo框架以及插件：
   ```
   npm install -g hexo-cli
   npm install hexo-deployer-git --save
   npm install hexo-renderer-pug hexo-renderer-stylus --save
   ```

#### 创建博客项目

1. 生成blog项目

   ```
   hexo init blog
   cd blog
   npm install
   ```
2. 编辑blog目录下的_config.yml中的配置

   ```
   # Hexo Configuration
   ## Docs: https://hexo.io/docs/configuration.html
   ## Source: https://github.com/hexojs/hexo/

   # Site
   title: soskong的博客
   subtitle: ''
   description: ''
   keywords:
   author: soskong
   language: zh-CN
   timezone: Asia/Shanghai

   # URL
   ## Set your site url here. For example, if you use GitHub Page, set url as 'https://username.github.io/project'
   url: http://soskong.github.io
   permalink: :year/:month/:day/:title/
   permalink_defaults:
   pretty_urls:
     trailing_index: true # Set to false to remove trailing 'index.html' from permalinks
     trailing_html: true # Set to false to remove trailing '.html' from permalinks

   # Directory
   source_dir: source
   public_dir: public
   tag_dir: tags
   archive_dir: archives
   category_dir: categories
   code_dir: downloads/code
   i18n_dir: :lang
   skip_render:

   # Writing
   new_post_name: :title.md # File name of new posts
   default_layout: post
   titlecase: false # Transform title into titlecase
   external_link:
     enable: true # Open external links in new tab
     field: site # Apply to the whole site
     exclude: ''
   filename_case: 0
   render_drafts: false
   post_asset_folder: false
   relative_link: false
   future: true
   syntax_highlighter: highlight.js
   highlight:
     line_number: true
     auto_detect: false
     tab_replace: ''
     wrap: true
     hljs: false
   prismjs:
     preprocess: true
     line_number: true
     tab_replace: ''

   # Home page setting
   # path: Root path for your blogs index page. (default = '')
   # per_page: Posts displayed per page. (0 = disable pagination)
   # order_by: Posts order. (Order by date descending by default)
   index_generator:
     path: ''
     per_page: 10
     order_by: -date

   # Category & Tag
   default_category: uncategorized
   category_map:
   tag_map:

   # Metadata elements
   ## https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta
   meta_generator: true

   # Date / Time format
   ## Hexo uses Moment.js to parse and display date
   ## You can customize the date format as defined in
   ## http://momentjs.com/docs/#/displaying/format/
   date_format: YYYY-MM-DD
   time_format: HH:mm:ss
   ## updated_option supports 'mtime', 'date', 'empty'
   updated_option: 'mtime'

   # Pagination
   ## Set per_page to 0 to disable pagination
   per_page: 10
   pagination_dir: page

   # Include / Exclude file(s)
   ## include:/exclude: options only apply to the 'source/' folder
   include:
   exclude:
   ignore:

   # Extensions
   ## Plugins: https://hexo.io/plugins/
   ## Themes: https://hexo.io/themes/
   theme: mango

   # Deployment
   ## Docs: https://hexo.io/docs/one-command-deployment
   deploy:
     type: git
     repo: git@github.com:soskong/soskong.github.io.git
     branch: main

   ```
3. 更换主题

   ```
   1. 下载主题项目，并将目录名改为theme_name
   2. 将_config.yml中的主题选项配置为[theme_name]
   3. 在blog目录下创建_config.[theme_name].yml,_config.[theme_name].yml为实际起作用的配置文件
   ```

#### 部署

在blog项目下

1. 清除缓存：`E:\nodejs\node_global\hexo.cmd clean`
2. 本地部署：`E:\nodejs\node_global\hexo.cmd server`
3. 远程部署到github：`E:\nodejs\node_global\hexo.cmd deploy`

#### 更新文章

在G:\Hexo\blog\source\\_posts创建md文件，在文件起始添加

```
---
title: dl_runtime_resolve
date: 2026-01-24 17:55:57
tags: 

---

```

同步

```
E:\nodejs\node_global\hexo.cmd deploy
```

#### 坑

1. 插件安装到theme文件夹下，主题目录名要改
2. 运行hexo时要运行hexo.cmd
