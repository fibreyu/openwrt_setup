本软件包在编译时，为luci-app-openclash自动添加clash核心

#### 一、编译说明

1. 首先安装golang编译环境

   ```bash
   # 进入安装目录
   cd opt
   # 下载文件
   wget https://dl.google.com/go/go1.19.2.linux-amd64.tar.gz
   # 解压
   tar xzvf go1.19.2.linux-amd64.tar.gz
   # 添加环境变量
   # vim /etc/profile
   export GOROOT=/opt/go
   export PATH=$PATH:$GOROOT/bin
   export GO111MODULE=on
   # 刷新变量
   source /etc/profile
   ```

2. 进入openwrt源码目录并将本项目源码放入package目录中

3. 修改Package中Makefile中`CLASH_ARCH`为指定架构，参考源文件makefile中的`PLATFORM_LIST`和`WINDOWS_ARCH_LIST`两个变量所列内容

#### 二、使用说明

1. 打开openclash界面

2. 添加订阅：`Config Update` -> `Config Subscribe Edit` -> `Add` -> `Commit Settings` -> `Update Config`

3. 开启clash: `Overviews` -> `Enable OpenClash`
4. 更新核心：`Config Manage` -> `Upload File Type ` -> `[Dev Core File]` -> `选择文件` -> `Upload`