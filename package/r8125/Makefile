# All rights reserved.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=r8125
PKG_VERSION:=9.009.02
PKG_RELEASE:=$(AUTORELEASE)

# PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/realtek-$(PKG_NAME)-$(PKG_VERSION)


PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILE:=LICENSE

PKG_MAINTAINER:=fibreyu <fibreyu@gmail.com>

include $(INCLUDE_DIR)/package.mk

define KernelPackage/r8125
  TITLE:=Driver for Realtek r8125 chipsets
  CATEGORY:=Kernel modules
  SUBMENU:=Network Devices
  VERSION:=$(LINUX_VERSION)+$(PKG_VERSION)-$(BOARD)-$(PKG_RELEASE)
  FILES:= $(PKG_BUILD_DIR)/src/r8125.ko
  AUTOLOAD:=$(call AutoProbe,r8125)
endef

define Package/r8125/description
  This package contains a driver for Realtek r8125 chipsets.
endef

define Build/Compile
	+$(KERNEL_MAKE) M="${PKG_BUILD_DIR}/src" modules
endef

$(eval $(call KernelPackage,r8125))