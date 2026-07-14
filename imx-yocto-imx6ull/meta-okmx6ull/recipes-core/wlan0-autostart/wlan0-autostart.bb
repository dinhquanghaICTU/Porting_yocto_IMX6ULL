SUMMARY = "Autostart wlan0 using ifupdown"
LICENSE = "CLOSED"

SRC_URI = "file://wlan0-autostart.service"

inherit systemd

SYSTEMD_SERVICE:${PN} = "wlan0-autostart.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
	install -d ${D}${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/wlan0-autostart.service ${D}${systemd_system_unitdir}/wlan0-autostart.service
}

FILES:${PN} += "${systemd_system_unitdir}/wlan0-autostart.service"

RDEPENDS:${PN} += "init-ifupdown wpa-supplicant rtl8723du"