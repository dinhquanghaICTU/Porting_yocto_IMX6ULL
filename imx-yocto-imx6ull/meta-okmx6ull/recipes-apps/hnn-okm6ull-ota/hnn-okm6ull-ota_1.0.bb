SUMMARY = "HNN OKM6ULL OTA MQTT LED application"
DESCRIPTION = "MQTT/button/LED OTA application for OKM6ULL"
LICENSE = "CLOSED"

DEPENDS = "mosquitto"
RDEPENDS:${PN} += "mosquitto"

SRC_URI = "git://github.com/dinhquanghaICTU/HNN_OKM6ULL_OTA.git;protocol=https;branch=main \
           file://hnn-okm6ull-ota.service"

SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"

inherit systemd

SYSTEMD_SERVICE:${PN} = "hnn-okm6ull-ota.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_compile() {
    oe_runmake clean

    oe_runmake \
        CC="${CC}" \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS} -fPIC -Ihardware -Iconfig -Imiddle/mqtt -Imiddle/ota -Ithird_party/jsmn" \
        LDFLAGS="${LDFLAGS} -lmosquitto -lpthread"
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/build/mqtt_led_app ${D}${bindir}/mqtt_led_app

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hnn-okm6ull-ota.service ${D}${systemd_system_unitdir}/hnn-okm6ull-ota.service
}

FILES:${PN} += "${systemd_system_unitdir}/hnn-okm6ull-ota.service"
