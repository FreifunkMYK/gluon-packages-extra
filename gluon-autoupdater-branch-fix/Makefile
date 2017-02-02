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

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
	$(call GluonSrcDiet,./luasrc,$(PKG_BUILD_DIR)/luadest/)
endef

define Package/gluon-autoupdater-branch-fix/install
	$(CP) $(PKG_BUILD_DIR)/luadest/* $(1)/
endef

$(eval $(call BuildPackage,gluon-autoupdater-branch-fix))
