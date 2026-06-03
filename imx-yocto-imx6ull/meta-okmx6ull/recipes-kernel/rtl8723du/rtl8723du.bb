LICENSE = "CLOSED"

# Lấy source driver local từ thư mục files của recipe.
SRC_URI = "file://rtl8723DU/"

# Dùng môi trường chuẩn để build kernel module ngoài tree kernel.
inherit module-base

# Build sau khi kernel target đã được chuẩn bị; bc-native cần cho một số Makefile kernel/module.
DEPENDS += "virtual/kernel bc-native"

# Thư mục source driver sau khi Yocto unpack vào WORKDIR.
S = "${WORKDIR}/rtl8723DU"

# Các biến truyền thêm cho Makefile của driver vendor:
# ARCH chọn kiến trúc target.
# CROSS_COMPILE là prefix cross compiler do Yocto cấp.
# KSRC trỏ tới thư mục kernel build đã chuẩn bị.
# CONFIG_* tắt các phần driver vendor không dùng cho board này.
# USER_EXTRA_CFLAGS bật cfg80211 và tránh lỗi build do warning bị coi là error.
EXTRA_OEMAKE += " \
    ARCH=arm \
    CROSS_COMPILE=${TARGET_PREFIX} \
    KSRC=${STAGING_KERNEL_BUILDDIR} \
    CONFIG_PLATFORM_I386_PC=n \
    CONFIG_BR_EXT=n \
    USER_EXTRA_CFLAGS='-DCONFIG_LITTLE_ENDIAN -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT -Wno-error' \
"

# Compile kernel module bằng Makefile của driver vendor.
do_compile() {
    unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
    oe_runmake modules
}

# Cài file .ko đã build và cấu hình tự load module khi boot.
do_install() {
    # Lấy đúng kernel ABI version để cài module vào đúng thư mục /lib/modules/<version>.
    kernel_version="$(cat ${STAGING_KERNEL_BUILDDIR}/kernel-abiversion)"

    # Cài external module vào /lib/modules/<kernel-version>/extra/.
    install -d ${D}${nonarch_base_libdir}/modules/${kernel_version}/extra
    install -m 0644 ${S}/8723du.ko \
        ${D}${nonarch_base_libdir}/modules/${kernel_version}/extra/8723du.ko

    # Tạo file modules-load.d để kmod/systemd tự load module 8723du khi boot.
    install -d ${D}${sysconfdir}/modules-load.d
    echo 8723du > ${D}${sysconfdir}/modules-load.d/8723du.conf
}

# Khi package được cài trên target đang chạy, chạy depmod để cập nhật metadata module.
pkg_postinst:${PN}() {
if [ -z "$D" ]; then
    depmod -a || true
fi
}

# Khai báo các file đã install thuộc package này, tránh lỗi installed-but-not-shipped.
FILES:${PN} += " \
    ${nonarch_base_libdir}/modules/*/extra/8723du.ko \
    ${sysconfdir}/modules-load.d/8723du.conf \
"

# Runtime cần kmod để load/quản lý kernel module trên target.
RDEPENDS:${PN} += "kmod"
