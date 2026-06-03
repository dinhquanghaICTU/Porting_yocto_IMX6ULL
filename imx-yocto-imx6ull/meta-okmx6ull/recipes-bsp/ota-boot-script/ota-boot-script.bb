LICENSE = "CLOSED"

#lay ra file boot.cmd de chuan bi compile ra boot.scr
SRC_URI = "file://boot.cmd"

#them class deploy cua Yocto, no se ho tro lam cac task deploy nó giống như format chuẩn 
inherit deploy

#recipe nay can tool mkimage cua U-Boot de chay tren may build host
DEPENDS += "u-boot-mkimage-native"

#lay file text boot.cmd, dung tool mkimage dong goi thanh script U-Boot ten boot.scr
do_compile() {
    mkimage -A arm -O linux -T script -C none \
        -n "OKM6ULL OTA boot script" \
        -d ${WORKDIR}/boot.cmd ${B}/boot.scr
}

#tao thu muc deploy, roi copy boot.scr va boot.cmd ra do
do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/boot.scr ${DEPLOYDIR}/boot.scr
    install -m 0644 ${WORKDIR}/boot.cmd ${DEPLOYDIR}/boot.cmd
}

#sau khi compile song sẽ chạy task deploy trước khi recipe build xong 
addtask deploy after do_compile before do_build