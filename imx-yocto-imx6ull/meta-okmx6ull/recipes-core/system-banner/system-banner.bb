SUMMARY = "Login banner for the OKMX6ULL OTA device"
LICENSE = "CLOSED"

SRC_URI = " \
    file://issue \
    file://banner-unicode \
    file://motd \
    file://okmx6ull-banner.sh \
"

do_install() {
    install -d ${D}${sysconfdir}/profile.d
    install -m 0644 ${WORKDIR}/issue ${D}${sysconfdir}/issue
    install -m 0644 ${WORKDIR}/banner-unicode ${D}${sysconfdir}/banner-unicode
    install -m 0644 ${WORKDIR}/motd ${D}${sysconfdir}/motd
    install -m 0755 ${WORKDIR}/okmx6ull-banner.sh \
        ${D}${sysconfdir}/profile.d/okmx6ull-banner.sh
}

FILES:${PN} += " \
    ${sysconfdir}/issue \
    ${sysconfdir}/banner-unicode \
    ${sysconfdir}/motd \
    ${sysconfdir}/profile.d/okmx6ull-banner.sh \
"
