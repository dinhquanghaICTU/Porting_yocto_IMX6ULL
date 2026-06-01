# Cho BitBake tìm thêm file patch/config/DTS trong thư mục linux-imx cạnh file .bbappend này.
FILESEXTRAPATHS:prepend := "${THISDIR}/linux-imx:"

# Thêm kernel config fragment để bật/cấu hình Ethernet.
SRC_URI += "file://ethernet.cfg"

# Thêm kernel config fragment để bật/cấu hình WiFi.
SRC_URI += "file://wifi.cfg"

# Thêm device tree custom cho board OKMX6ULL-S eMMC.
SRC_URI += "file://imx6ull-14x14-evk-emmc.dts"

# Trước bước configure kernel, copy DTS custom vào cây source kernel để kernel build ra DTB.
do_configure:prepend() {
    cp ${WORKDIR}/imx6ull-14x14-evk-emmc.dts \
       ${S}/arch/arm/boot/dts/imx6ull-14x14-evk-emmc.dts
}
