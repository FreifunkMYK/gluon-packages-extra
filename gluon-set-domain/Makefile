include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-set-domain
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-set-domain
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=Set Domain for upgrade to 2018.1.1
  DEPENDS:=+gluon-core +lua-simple-uci
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
	$(call GluonSrcDiet,./luasrc,$(PKG_BUILD_DIR)/luadest/)
endef

define Package/gluon-set-domain/install
	$(CP) $(PKG_BUILD_DIR)/luadest/* $(1)/
endef

$(eval $(call BuildPackage,gluon-set-domain))
