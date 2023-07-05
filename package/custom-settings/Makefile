include $(TOPDIR)/rules.mk

PKG_NAME:=custom-settings
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=fibreyu

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/custom-settings
  SECTION:=net
  CATEGORY:=Network
  TITLE:=base settings
  PKGARCH:=all
  DEPENDS:=+base-files
endef

define Package/custom-settings/description
  base settings
endef

define Build/Configure
endef

define Build/Compile
  $(CP) ./files/* $(PKG_BUILD_DIR)
endef

define Package/custom-settings/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/custom-settings $(1)/etc/uci-defaults/99-custom-settings
endef

$(eval $(call BuildPackage,custom-settings))