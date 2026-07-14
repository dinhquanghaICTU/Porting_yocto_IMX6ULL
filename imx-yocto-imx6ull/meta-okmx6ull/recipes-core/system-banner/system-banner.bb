SUMMARY = "Login banner for the OKMX6ULL OTA device"
LICENSE = "CLOSED"

SRC_URI = "     file://banner-unicode     file://okmx6ull-banner.sh "

do_install() {
    install -d ${D}${sysconfdir}/profile.d
    install -m 0644 ${WORKDIR}/banner-unicode ${D}${sysconfdir}/banner-unicode
    install -m 0755 ${WORKDIR}/okmx6ull-banner.sh         ${D}${sysconfdir}/profile.d/okmx6ull-banner.sh
}

FILES:${PN} += "     ${sysconfdir}/banner-unicode     ${sysconfdir}/profile.d/okmx6ull-banner.sh "
