#
# Copyright (C) 2008-2022 fibreyu
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-socat
PKG_VERSION:=1.7.4.1
PKG_RELEASE:=20221015
PKG_MAINTAINER:=fibreyu
LUCI_TITLE:=socat
LUCI_DEPENDS:=+socat
LUCI_PKGARCH:=all

define Package/${PKG_NAME}/postinst
#!/bin/sh
# if [ -z "$${IPKG_INSTROOT}" ]; then

# 清空注释
sed -i -e 's/^[[:space:]]*//' \
	-e '/^#[[:space:]]\|^#$$/d' \
	-e 's/[[:space:]]#[[:space:]].*$$//' \
	-e 's/[[:space:]]*$$//' \
	-e '/^\/\/[[:space:]]/d'	\
	-e '/^[[:space:]]*$$/d'	$${IPKG_INSTROOT}/etc/init.d/socat ;

# 添加执行权限
chmod a+x $${IPKG_INSTROOT}/etc/init.d/socat

# luci.mk 中定义的
rm -f /tmp/luci-indexcache.*
rm -rf /tmp/luci-modulecache/
killall -HUP rpcd 2>/dev/null
exit 0

#fi

endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature