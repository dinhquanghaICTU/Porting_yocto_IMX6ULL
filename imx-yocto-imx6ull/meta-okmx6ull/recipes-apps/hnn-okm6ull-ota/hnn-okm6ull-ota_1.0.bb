LICENSE = "CLOSED"

# add mosquitto vao luc build
# them file header cua mosquitto vao
DEPENDS = "mosquitto"

# cho lib .so cua mosquitto chay runtime tren board
RDEPENDS:${PN} += "mosquitto"

# source app tren git de keo ve va build
# them service chinh va service rollback vao rootfs
SRC_URI = "git://github.com/dinhquanghaICTU/HNN_OKM6ULL_OTA.git;protocol=https;branch=main \
           file://hnn-okm6ull-ota.service \
           file://ota-app-rollback.service"

# chi dinh thu muc source sau khi keo ve nam o source git de compile lai
SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"

# dung class systemd de enable/disable service
inherit systemd

# cho bitbake biet cac file service ten gi
SYSTEMD_SERVICE:${PN} = "hnn-okm6ull-ota.service ota-app-rollback.service"

# tu dong chay service luc boot
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# build app bang compiler cua Yocto
do_compile() {
    oe_runmake clean

    oe_runmake \
        CC="${CC}" \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS} -fPIC -Ihardware -Iconfig -Imiddle/mqtt -Imiddle/ota -Ithird_party/jsmn" \
        LDFLAGS="${LDFLAGS} -lmosquitto -lpthread"
}

# cai app va cac service vao rootfs
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/build/mqtt_led_app ${D}${bindir}/mqtt_led_app

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hnn-okm6ull-ota.service ${D}${systemd_system_unitdir}/hnn-okm6ull-ota.service
    install -m 0644 ${WORKDIR}/ota-app-rollback.service ${D}${systemd_system_unitdir}/ota-app-rollback.service
}

# hay dua cac file nay vao package
FILES:${PN} += " \
    ${systemd_system_unitdir}/hnn-okm6ull-ota.service \
    ${systemd_system_unitdir}/ota-app-rollback.service \
"