# ws
云服务器程序一键部署脚本

所用.sh脚本在下载好运行是请先添加执行权限（在root用户下）
```shell
chmod +x [文件名]
```
接下来运行程序
```shell
./[filename]
```

安装Git：

如果您还没有安装Git，需要先从Git官网下载并安装。


克隆整个仓库：

打开命令行终端
使用以下命令克隆整个仓库：

git clone https://github.com/用户名/仓库名.git

例如：
```
git clone https://github.com/Gowilll/ws.git
```



下载特定分支：

如果只想下载特定分支，可以使用：

git clone -b 分支名 https://github.com/用户名/仓库名.git

仅下载最新版本（浅克隆）：

如果仓库历史记录很大，但您只需要最新版本：

git clone --depth 1 https://github.com/用户名/仓库名.git

下载单个文件（不使用Git克隆）：

对于单个文件，您可以直接在GitHub网页上点击该文件
点击"Raw"按钮
在浏览器中右键保存页面内容
或者使用curl或wget命令：

curl -O https://raw.githubusercontent.com/用户名/仓库名/分支名/路径/文件名


首先，完成脚本的剩余部分，从我提供的最后一行代码继续：
