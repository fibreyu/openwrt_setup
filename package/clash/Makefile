include $(TOPDIR)/rules.mk

PKG_NAME:=clash
PKG_VERSION:=1.11.8
PKG_RELEASE:=1
CLASH_ARCH:=linux-amd64-v3

PKG_MAINTAINER:=fibreyu <fibreyu@gmail.com>
PKG_BUILD_PARALLEL:=1
PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILE:=LICENSE

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Dreamacro/clash/archive/v$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=573fcf59648a4eee6ac8cd0a0d4717cc55f350beb866923749d343f17ff77f11

include $(INCLUDE_DIR)/package.mk

define Package/clash
  SECTION:=net
  CATEGORY:=Network
  TITLE:=clash
  MAINTAINER:=fibreyu
  URL:=https://github.com/Dreamacro/clash
  DEPENDS:=
endef

define Package/clash/description
a proxy called clash.
endef

define Build/Compile
	sed -i 's/all: linux-amd64 darwin-amd64 windows-amd64/all: $(CLASH_ARCH)/' $(PKG_BUILD_DIR)/Makefile
	$(MAKE) -C $(PKG_BUILD_DIR)
endef

define Package/clash/install
	$(INSTALL_DIR) $(1)/etc/openclash/core
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/clash-$(CLASH_ARCH) $(1)/etc/openclash/core/clash
endef

define Package/clash/prerm
	#!/bin/sh
	# if NOT run buildroot then kill clash process
	[ -z "$${IPKG_INSTROOT}" ] && killall -9 clash >/dev/null 2>&1
	# remove core clash file
	rm -rf $${IPKG_INSTROOT}/etc/openclash/core/clash >/dev/null 2>&1
	exit 0 # suppress errors
endef

$(eval $(call BuildPackage,clash))