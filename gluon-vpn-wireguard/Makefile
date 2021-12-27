include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-vpn-wireguard
PKG_VERSION:=1
PKG_RELEASE:=1

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-vpn-wireguard
  TITLE:=Support for connecting via wireguard
  DEPENDS:=+gluon-mesh-vpn-core +micrond +kmod-wireguard +wireguard-tools +ip-full
endef

$(eval $(call BuildPackageGluon,gluon-vpn-wireguard))
