#!/bin/bash

####################
# system base tool #
####################
sudo apt update
sudo apt install -y build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
gettext git libncurses-dev libssl-dev python3-distutils rsync unzip zlib1g-dev \
file wget
sudo apt install -y build-essential gawk gcc-multilib flex git gettext \
libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev curl
sudo apt -y upgrade

##################
# clone src code #
##################
git clone -b openwrt-23.05 https://github.com/openwrt/openwrt.git ~/openwrt
git clone https://github.com/fibreyu/openwrt_setup.git ~/openwrt_setup

############
# add pkgs #
############

# custom-settings
cp -a ~/openwrt_setup/package/custom-settings ~/openwrt/package/
# add ddns-scripts-aliyun
cp -a ~/openwrt_setup/package/ddns-scripts-aliyun ~/openwrt/package/
# add ddns-scripts-dnspod-v1
cp -a ~/openwrt_setup/package/ddns-scripts-dnspod-v1 ~/openwrt/package/
# add socat
cp -a ~/openwrt_setup/package/luci-app-socat ~/openwrt/package/
# add socat
cp -a ~/openwrt_setup/package/r8125 ~/openwrt/package/

cd ~/openwrt/package/
# add unblockneteasemusic
git clone https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic.git
# add luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git
# add OpenAppFilter
git clone https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# add openclash
cd ~/openwrt/
mkdir package/luci-app-openclash-tmp
cd package/luci-app-openclash-tmp
git init
git remote add -f origin https://github.com/vernesong/OpenClash.git
git config core.sparsecheckout true
echo "luci-app-openclash" >> .git/info/sparse-checkout
git pull --depth 1 origin master
git branch --set-upstream-to=origin/master master
cp -a luci-app-openclash ../luci-app-openclash
cd ..
rm -rf luci-app-openclash-tmp


cd ~/openwrt/
./scripts/feeds update -a
./scripts/feeds install -a

cp ~/openwrt_setup/diff.config ~/openwrt/.config
make defconfig
make download -j1 V=s
find dl -size -1024c -exec rm -f {} \;
make download -j1 V=s
make -j1 V=s 
