FILESEXTRAPATHS:prepend := "${THISDIR}/init-ifupdown:"

SRC_URI:append:okmx6ull-s-emmc = " file://interfaces file://wpa_supplicant.conf"

do_install:append:okmx6ull-s-emmc() {
    install -d ${D}${sysconfdir}/wpa_supplicant
    install -m 0600 ${WORKDIR}/wpa_supplicant.conf ${D}${sysconfdir}/wpa_supplicant/wpa_supplicant.conf
}
