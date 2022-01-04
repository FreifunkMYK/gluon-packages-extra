#
# Copyright (C) 2016-2017 Dan Luedtke <mail@danrl.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=jool-stateless
PKG_VERSION:=3.5.7
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/NICMx/Jool/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=b8e95d1526cd2434dedbae292afd2d17f0780ac2dca2be21264712b41eb76a3d
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/Jool-$(PKG_VERSION)

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING

PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=USE_UCLIBC:argp-standalone USE_MUSL:argp-standalone

PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

MAKE_PATH:=usr
CONFIGURE_PATH:=usr

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		KERNEL_DIR="$(LINUX_DIR)" \
		ARCH="$(LINUX_KARCH)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		SUBDIRS="$(PKG_BUILD_DIR)/mod/stateless" \
		V="$(V)" \
		modules
	$(call Build/Compile/Default)
endef

define Package/jool-stateless/Default
  SECTION:=net
  CATEGORY:=Network
  URL:=https://www.jool.mx
endef

define Package/jool-stateless/Default/description
  Jool is an Open Source SIIT for Linux.
endef

define Package/jool-stateless
  $(call Package/jool-stateless/Default)
  TITLE:=Jool meta-package
  DEPENDS:=+kmod-jool-stateless +jool-tools-stateless
endef

define Package/jool-stateless/description
  $(call Package/jool-stateless/Default/description)
endef

define KernelPackage/jool-stateless
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Support
  TITLE:=Jool kernel module
  DEPENDS:= \
    @IPV6 \
    +kmod-crypto-md5 \
    +kmod-nf-conntrack \
    +kmod-nf-conntrack6
  FILES:= \
    $(PKG_BUILD_DIR)/mod/stateless/jool_siit.$(LINUX_KMOD_SUFFIX)
endef

define KernelPackage/jool-stateless/description
  $(call Package/jool-stateless/Default/description)

  This package provides the kernel module for Jool.
endef

define Package/jool-tools-stateless
  $(call Package/jool-stateless/Default)
  TITLE:=Jool userspace control programs
  DEPENDS:=+libnl-genl +ethtool
endef

define Package/jool-tools-stateless/description
  $(call Package/jool-stateless/Default/description)

  This package provides the userspace control programs for Jool.
endef

define Package/jool-tools-stateless/install
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/usr/stateless/jool_siit $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,jool-stateless))
$(eval $(call KernelPackage,jool-stateless))
$(eval $(call BuildPackage,jool-tools-stateless))
