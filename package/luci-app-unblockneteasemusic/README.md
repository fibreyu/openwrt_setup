```
#进入 OpenWrt 源码 package 目录
    cd package
    #克隆插件源码
    git clone https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic.git
    #返回上一层目录
    cd ..
    #配置
    make menuconfig
    #在 luci -> application 选中插件，开始编译
    make package/luci-app-unblockneteasemusic/compile V=s
```