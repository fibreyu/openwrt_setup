#!/bin/bash
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
