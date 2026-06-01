
#kấy ra file boot.cmd. để chuẩn bị compilẻ ra boot.scr
SRC_URI = "file://boot.cmd"

thêm class deploy của Yocto, nó sẽ hỗ trợ làm các task
inherit deploy

#recipe này cần tool mkimage của U-Boot để chạy trên máy build host.
DEPENDS += "u-boot-mkimage-native"


#Lấy file text boot.cmd, dùng tool mkimage đóng gói nó thành script U-Boot tên boot.scr.
do_compile() {
    mkimage -A arm -O linux -T script -C none \
        -n "OKM6ULL OTA boot script" \
        -d ${WORKDIR}/boot.cmd ${B}/boot.scr
}
#tạo thư mục deploy, rồi copy boot.scr và cả boot.cmd ra đó
do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/boot.scr ${DEPLOYDIR}/boot.scr
    install -m 0644 ${WORKDIR}/boot.cmd ${DEPLOYDIR}/boot.cmd
}

addtask deploy after do_compile before do_build
