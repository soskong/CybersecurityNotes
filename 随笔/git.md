#### 仓库

1. 初始化git，在当前目录下创建directory_name仓库，并且在directory_name目录下初始化git
   不加参数将当前目录当作仓库

   ```
   git init [directory_name]
   ```
2. 创建远程仓库

   ```
   git remote add [remote_repo] https://xxx.git
   ```
3. 拉取远程项目

   ```
   git clone https://xxx.git	# 该命令相当于一个完整的创建流程，包括初始化仓库，切换到该目录并拉取master分支代码
   git clone -b [branch-name] --single-branch https://xxx.git	# 拉取指定分支代码
   ```

#### fetch

1. 拉取远程仓库所有分支的更新（不合并）

   ```
   git fetch [remote_repo]		# 拉取所有
   git fetch [remote_repo] [remote_branch_name]	# 指定分支
   ```

#### 分支

1. 查看分支

   ```
   git branch	# 查看本地分支
   git branch -r 	# 查看远程分支
   git branch -a 	# 查看全部分支
   ```
2. 创建分支

   ```
   git branch [branch_name] [source_branch_name]

   git branch --orphan [branch_name]
   # 创建一个空的分支，保留当前工作区内容，可通过 git rm -rf . 来清空当前工作区
   # 任何分支只有commit过才会被git记住，如果创建空白分支后没有commit，就切换到别的分支，commit分支会丢失
   ```

   基于一个分支创建分支，当第二个参数不填时，默认当前分支
3. 切换分支，与本地分支，无法切换到远程分支：注！，切换分支时工作目录中的代码会改变，基于git的快照存储

   ```
   git checkout [branch_name]
   git switch [branch_name]	# 高版本git也可使用switch命令
   ```
4. 创建远程分支

   并没有直接基于远程分支创建远程分支的操作，需要先创建本地分支，然后再同步到远程

   ```
   git checkout -b [branch_name] [source_branch_name] 	#  checkout -b 即创建并切换
   git push [remote_repo] [branch_name]			#  分支存在时，远程被本地同步，分支不存在时创建
   git push -u [remote_repo] [branch_name]		# 当使用-u参数后，本地分支和远程分支默认绑定，下次同步时，只需git push或git pull
   ```
5. 删除本地分支

   ```
   git branch -d [branch_name]
   ```
6. 删除远程分支

   ```
   git push [remote_repo] --delete [branch_name]
   ```
7. 合并

   ```
   git checkout main         # 先切换到接收改动的分支
   git merge feature         # 把 feature 分支的改动合并进当前 main 分支
   ```

   当想远程合并分支时要先将两分支拉到本地，本地合并后推送到远程
8. 改动本地分支内容，只能对当前分支操作

   * 将内容添加到暂存区

     ```
     git add [file_path]
     git add . 		# 将全部文件添加到暂存区
     ```
   * 提交文件到当前分支

     ```
     git commit -m [log_message]
     ex: git commit -m "Add myfile"
     ```

#### 同步

1. pull

   ```
   git pull [remote_repo] [remote_branch_name]
   ```

   会把远程仓库的分支的最新代码拉下来，并自动合并到你当前所在的本地分支

   ```
   所谓合并，并不是简单的替换，而是三方合并
   ```
2. push

   ```
   git push [remote_repo] [branch_name]
   ```

   会把本地分支推送到远程库对应的同名分支

#### fork

在当前工作目录下添加两个远程仓库，并获取更新

```
git remote add up-stream [source_project]
git remote add origin [your_project]

git fetch upstream
git fetch origin 
```

将源项目的分支拉到本地

```
git branch source-main [up-stream/master]
```

基于master分支，创建自己的分支并推送到远程

```
git checkout -b master
git push [your_project] master
```

### 搭建github page

1. 创建[username].github.io储存仓库
2. 将你想要的Jekyll主题克隆到你的[username].github.io储存仓库

   ```
   w1. 克隆源仓库
   git clone https://github.com/bencentra/centrarium.git
   2. 将目标仓库作为远程仓库d31imiter添加到本地
   git remote add d31imiter https://github.com/D31imiter/d31imiter.github.io
   3. 将本地仓库内容推送到远程仓库的master分支
   git push https://D31imiter@github.com/D31imiter/d31imiter.github.io.git master
   ```
3. 更新后的同步0

   ```
   git add .
   git commit -m "test"
   git push d31imiter master
   ```

#### 下载文件

通常需要clone整个项目，网站[DownGit](https://minhaskamal.github.io/DownGit/#/home)，可以做到下载单个文件

或者使用GitZip for github插件
