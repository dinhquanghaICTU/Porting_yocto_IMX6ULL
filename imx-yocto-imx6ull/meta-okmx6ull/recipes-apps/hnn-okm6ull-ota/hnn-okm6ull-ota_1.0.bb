# add mosquitto vao luc build
# them files header cua mosquitto vao
DEPENDS = "mosquitto"
#cho lib .so cua mosquitto chay runtime tren board
RDEPENDS:${PN} += "mosquitto"


#source app tren git de keo ve va build 
SRC_URI = "git://github.com/dinhquanghaICTU/HNN_OKM6ULL_OTA.git;protocol=https;branch=main \
           file://hnn-okm6ull-ota.service"


#chi dinh thu muc source sau khi keo ve nam o source git dẻ commpile lai 
SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"

#no se ung dung cho các cau lenh duoi de biet add vao service nao can ennable hay disable
inherit systemd

#cho bitbake biet file service ten gi, install o dau 
SYSTEMD_SERVICE:${PN} = "hnn-okm6ull-ota.service"
#co tu chạy luc boot khong 
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

#bitbake se lam xóa file build cũ ep build bang compiler của yocto vi cái makefile trong src thi duong dan se khac  
do_compile() {
    oe_runmake clean

    oe_runmake \
        CC="${CC}" \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS} -fPIC -Ihardware -Iconfig -Imiddle/mqtt -Imiddle/ota -Ithird_party/jsmn" \
        LDFLAGS="${LDFLAGS} -lmosquitto -lpthread"
}

#tao thu muc cho file .bin (arm) sau khi build song
# tao thu muc cho service systemsystem

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/build/mqtt_led_app ${D}${bindir}/mqtt_led_app

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hnn-okm6ull-ota.service ${D}${systemd_system_unitdir}/hnn-okm6ull-ota.service
}
#hay duu file nay vao package 
FILES:${PN} += "${systemd_system_unitdir}/hnn-okm6ull-ota.service"
