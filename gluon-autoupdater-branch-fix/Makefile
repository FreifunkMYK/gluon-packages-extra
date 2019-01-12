include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-autoupdater-branch-fix
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-autoupdater-branch-fix
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=Fix autoupdater branch
  DEPENDS:=+gluon-core +gluon-autoupdater
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
