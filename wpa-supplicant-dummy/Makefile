include $(TOPDIR)/rules.mk

PKG_NAME:=wpa-supplicant-dummy
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/wpa-supplicant-dummy
  SECTION:=ffho
  CATEGORY:=FFHO
  TITLE:=dummy wpa_supplicant from ffho-autoupdater-wifi-fallback
  DEPENDS:=+iw
  MAINTAINER:=Freifunk Hochstift <kontakt@hochstift.freifunk.net>
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
