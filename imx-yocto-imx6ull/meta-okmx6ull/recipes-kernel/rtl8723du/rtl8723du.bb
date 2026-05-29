SUMMARY = "RTL8723DU WiFi kernel module"
LICENSE = "CLOSED"

SRC_URI = "file://rtl8723DU/"

inherit module-base

DEPENDS += "virtual/kernel bc-native"

S = "${WORKDIR}/rtl8723DU"

EXTRA_OEMAKE += " \
    ARCH=arm \
    CROSS_COMPILE=${TARGET_PREFIX} \
    KSRC=${STAGING_KERNEL_BUILDDIR} \
    CONFIG_PLATFORM_I386_PC=n \
    CONFIG_BR_EXT=n \
    USER_EXTRA_CFLAGS='-DCONFIG_LITTLE_ENDIAN -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT -Wno-error' \
"

do_compile() {
    unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
    oe_runmake modules
}

do_install() {
    kernel_version="$(cat ${STAGING_KERNEL_BUILDDIR}/kernel-abiversion)"
    install -d ${D}${nonarch_base_libdir}/modules/${kernel_version}/extra
    install -m 0644 ${S}/8723du.ko \
        ${D}${nonarch_base_libdir}/modules/${kernel_version}/extra/8723du.ko

    install -d ${D}${sysconfdir}/modules-load.d
    echo 8723du > ${D}${sysconfdir}/modules-load.d/8723du.conf
}

pkg_postinst:${PN}() {
if [ -z "$D" ]; then
    depmod -a || true
fi
}

FILES:${PN} += " \
    ${nonarch_base_libdir}/modules/*/extra/8723du.ko \
    ${sysconfdir}/modules-load.d/8723du.conf \
"

RDEPENDS:${PN} += "kmod"
