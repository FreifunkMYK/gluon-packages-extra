include $(TOPDIR)/rules.mk

PKG_NAME:=ffffm-button-bind
PKG_VERSION:=1
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/$(PKG_NAME)
  SECTION:=gluon
  CATEGORY:=Gluon
  MAINTAINER:=Freifunk Frankfurt
  TITLE:=Button feature set binding
  DEPENDS:=+gluon-web-admin
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
