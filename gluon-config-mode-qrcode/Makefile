include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-config-mode-qrcode
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/gluon-config-mode-qrcode
  SECTION:=gluon
  CATEGORY:=Gluon
  DEPENDS:=+
  TITLE:=Display node registration link as QR-Code 
endef


define Package/gluon-legacy/description
	Display node registration link as QR-Code 
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/luadest
endef

define Build/Configure
endef

define Build/Compile
	$(call GluonSrcDiet,./luasrc,$(PKG_BUILD_DIR)/luadest/)
endef

define Package/gluon-config-mode-qrcode/install
	$(CP) $(PKG_BUILD_DIR)/luadest/* $(1)/
	$(CP) ./files/* $(1)/
endef

define Package/gluon-config-mode-qrcode/postinst
#!/bin/sh
$(call GluonCheckSite,check_site.lua)
endef

$(eval $(call BuildPackage,gluon-config-mode-qrcode))
