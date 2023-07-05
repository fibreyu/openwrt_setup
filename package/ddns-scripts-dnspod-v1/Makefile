include $(TOPDIR)/rules.mk

PKG_NAME:=ddns-scripts-dnspod-v1
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=Small_5

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/ddns-scripts-dnspod-v1/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  PKGARCH:=all
endef

define Package/ddns-scripts-dnspod-v1-com
  $(call Package/ddns-scripts-dnspod-v1/Default)
  TITLE:=ddns-scripts-dnspod-v1-com
  DEPENDS:=ddns-scripts +wget-ssl +ca-bundle
endef



define Package/ddns-scripts-dnspod-v1-com/description
  Dynamic DNS Client scripts extension for Dnspod.com
endef

define Package/ddns-scripts-dnspod-v1-cn
  $(call Package/ddns-scripts-dnspod-v1/Default)
  TITLE:=ddns-scripts-dnspod-v1-cn
  DEPENDS:=ddns-scripts +wget-ssl +ca-bundle
endef

define Package/ddns-scripts-dnspod-v1-cn/description
  Dynamic DNS Client scripts extension for Dnspod.cn
endef

define Build/Configure
endef

define Build/Compile
	$(CP) ./*.sh $(PKG_BUILD_DIR)
	$(CP) ./*.json $(PKG_BUILD_DIR)
endef

define Package/ddns-scripts-dnspod-v1-cn/preinst
	#!/bin/sh
	# if NOT run buildroot then stop service
	[ -z "$${IPKG_INSTROOT}" ] && /etc/init.d/ddns stop >/dev/null 2>&1
	exit 0 # suppress errors
endef


define Package/ddns-scripts-dnspod-v1-cn/install
	$(INSTALL_DIR) $(1)/usr/lib/ddns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/update_dnspod_cn.sh $(1)/usr/lib/ddns

	$(INSTALL_DIR) $(1)/usr/share/ddns/default
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dnspod.cn.json $(1)/usr/share/ddns/default
endef

define Package/ddns-scripts-dnspod-v1-cn/prerm
	#!/bin/sh
	# if NOT run buildroot then stop service
	[ -z "$${IPKG_INSTROOT}" ] && /etc/init.d/ddns stop >/dev/null 2>&1
	# remove services file entries
	rm -rf $${IPKG_INSTROOT}/usr/lib/ddns/update_dnspod_cn.sh >/dev/null 2>&1
	rm -rf $${IPKG_INSTROOT}/usr/share/ddns/default/dnspod.cn.json >/dev/null 2>&1
	exit 0 # suppress errors
endef

define Package/ddns-scripts-dnspod-v1-com/preinst
	#!/bin/sh
	# if NOT run buildroot then stop service
	[ -z "$${IPKG_INSTROOT}" ] && /etc/init.d/ddns stop >/dev/null 2>&1
	exit 0 # suppress errors
endef

define Package/ddns-scripts-dnspod-v1-com/install
	$(INSTALL_DIR) $(1)/usr/lib/ddns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/update_dnspod_com.sh $(1)/usr/lib/ddns

	$(INSTALL_DIR) $(1)/usr/share/ddns/default
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dnspod.com.json $(1)/usr/share/ddns/default
endef

define Package/ddns-scripts-dnspod-v1-com/prerm
	#!/bin/sh
	# if NOT run buildroot then stop service
	[ -z "$${IPKG_INSTROOT}" ] && /etc/init.d/ddns stop >/dev/null 2>&1
	# remove services file entries
	rm -rf $${IPKG_INSTROOT}/usr/lib/ddns/update_dnspod_com.sh >/dev/null 2>&1
	rm -rf $${IPKG_INSTROOT}/usr/share/ddns/default/dnspod.com.json >/dev/null 2>&1
	exit 0 # suppress errors
endef

$(eval $(call BuildPackage,ddns-scripts-dnspod-v1-com))
$(eval $(call BuildPackage,ddns-scripts-dnspod-v1-cn))