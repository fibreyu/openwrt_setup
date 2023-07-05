```bash
cd openwrt/package
git clone https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter
echo "CONFIG_PACKAGE_luci-app-oaf=y" >>.config
make defconfig
make -j1 V=s  
```