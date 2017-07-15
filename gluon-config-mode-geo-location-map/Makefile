include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-config-mode-geo-location-map
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
PKG_BUILD_DEPENDS:=node/host

include $(TOPDIR)/../package/gluon.mk

RJS_VERSION:=2.1.10
RJS:=r-$(RJS_VERSION).js
define Download/rjs
	FILE:=$(RJS)
	URL:=http://requirejs.org/docs/release/$(RJS_VERSION)
	URL_FILE:=r.js
	HASH:=d0b7cfd962a7f8ac52a5d528df486341eed856609d9c75fa2566a32900f5b143
endef
$(eval $(call Download,rjs))

PKG_CONFIG_DEPENDS += $(GLUON_I18N_CONFIG)

define Package/gluon-config-mode-geo-location-map
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=Set geographic location of a node
  DEPENDS:=gluon-config-mode-core-virtual +gluon-node-info
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(DL_DIR)/$(RJS) $(PKG_BUILD_DIR)/r.js
endef

define Build/Configure
	$(CP) ./jssrc/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	cd $(PKG_BUILD_DIR) && \
		node r.js -o build.js
	$(call GluonBuildI18N,gluon-config-mode-geo-location-map,i18n)
	$(call GluonSrcDiet,./luasrc,$(PKG_BUILD_DIR)/luadest/)
endef

define Package/gluon-config-mode-geo-location-map/install
	$(CP) $(PKG_BUILD_DIR)/luadest/* $(1)/
	$(INSTALL_DIR) $(1)/lib/gluon/web/www/static/gluon/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/osm.js $(1)/lib/gluon/web/www/static/gluon/
	$(call GluonInstallI18N,gluon-config-mode-geo-location-map,$(1))
endef

define Package/gluon-config-mode-geo-location-map/postinst
#!/bin/sh
$(call GluonCheckSite,check_site.lua)
endef

$(eval $(call BuildPackage,gluon-config-mode-geo-location-map))
