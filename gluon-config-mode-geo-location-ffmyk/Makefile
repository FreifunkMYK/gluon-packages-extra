include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-config-mode-geo-location-ffmyk
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-config-mode-geo-location-ffmyk
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=Set geographic location of a node
  DEPENDS:=+gluon-config-mode-core +gluon-node-info
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/gluon-config-mode-geo-location-ffmyk/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,gluon-config-mode-geo-location-ffmyk))
