FILESEXTRAPATHS:prepend := "${THISDIR}/linux-imx:"

SRC_URI += "file://ethernet.cfg"
SRC_URI += "file://wifi.cfg"
SRC_URI += "file://imx6ull-14x14-evk-emmc.dts"

do_configure:prepend() {
    cp ${WORKDIR}/imx6ull-14x14-evk-emmc.dts \
       ${S}/arch/arm/boot/dts/imx6ull-14x14-evk-emmc.dts
}
