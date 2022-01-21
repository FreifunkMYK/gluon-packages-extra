#
# Copyright (C) 2016-2017 Dan Luedtke <mail@danrl.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=jool-stateless
PKG_VERSION:=4.1.6
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE_PROTO:=git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/FreifunkMYK/jool-stateless.git
PKG_SOURCE_VERSION:=5ddc9df90216684986e4c75725877bb4a49752b9
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/jool-stateless-$(PKG_VERSION)

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=COPYING

PKG_FIXUP:=autoreconf

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=USE_UCLIBC:argp-standalone USE_MUSL:argp-standalone

include $(INCLUDE_DIR)/package.mk

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		KERNEL_DIR="$(LINUX_DIR)" \
		ARCH="$(LINUX_KARCH)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		M="$(PKG_BUILD_DIR)/src/mod/common" \
		V="$(V)" \
		modules
	$(MAKE) -C "$(LINUX_DIR)" \
		KERNEL_DIR="$(LINUX_DIR)" \
		ARCH="$(LINUX_KARCH)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		M="$(PKG_BUILD_DIR)/src/mod/siit" \
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
    +kmod-nf-conntrack \
    +kmod-nf-conntrack6
  FILES:= \
    $(PKG_BUILD_DIR)/src/mod/common/jool_common.$(LINUX_KMOD_SUFFIX) \
    $(PKG_BUILD_DIR)/src/mod/siit/jool_siit.$(LINUX_KMOD_SUFFIX)
endef

define KernelPackage/jool-stateless/description
  $(call Package/jool-stateless/Default/description)

  This package provides the kernel module for Jool.
endef

define Package/jool-tools-stateless
  $(call Package/jool-stateless/Default)
  TITLE:=Jool userspace control programs
  DEPENDS:=+libnl-genl
endef

define Package/jool-tools-stateless/description
  $(call Package/jool-stateless/Default/description)

  This package provides the userspace control programs for Jool.
endef

CONFIGURE_ARGS += \
  --disable-shared \
  --without-bash-completion-dir

CONFIGURE_VARS += \
  ac_cv_func_memset=yes \
  ac_cv_func_strcasecmp=yes

define Package/jool-tools-stateless/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/jool_siit	$(1)/usr/bin/
endef

$(eval $(call KernelPackage,jool-stateless))
$(eval $(call BuildPackage,jool-tools-stateless))
