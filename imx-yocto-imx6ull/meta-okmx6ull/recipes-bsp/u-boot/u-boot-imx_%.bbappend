
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " file://okmx6ull_s_emmc_defconfig"


SRC_URI += " file://command_blink_led.c"


SRC_URI += " file://command_button_jump_kernel.c"


SRC_URI += " file://0001-mx6ull-set-onoff-hold-time-to-10-seconds.patch"

do_configure:prepend() {

    install -m 0644 ${WORKDIR}/command_blink_led.c ${S}/cmd/

    sed -i '/command_blink_led\.o/d' ${S}/cmd/Makefile
    sed -i '/gpio\.o/a obj-$(CONFIG_CMD_GPIO) += command_blink_led.o' \
    ${S}/cmd/Makefile

    install -m 0644 ${WORKDIR}/command_button_jump_kernel.c \
        ${S}/cmd/
    
    sed -i '/command_button_jump_kernel\.o/d' ${S}/cmd/Makefile
    sed -i '/command_blink_led\.o/a obj-y += command_button_jump_kernel.o' \
        ${S}/cmd/Makefile

    install -m 0644 ${WORKDIR}/okmx6ull_s_emmc_defconfig \
        ${S}/configs/okmx6ull_s_emmc_defconfig

    sed -i 's/if (IS_ENABLED(CONFIG_OF_SYSTEM_SETUP))/if (0)/' \
        ${S}/boot/image-fdt.c

    CFG="${S}/board/freescale/mx6ullevk/imximage.cfg"

    sed -i 's/0x021B080C 0x00000004/0x021B080C 0x00000001/' $CFG
    sed -i 's/0x021B083C 0x41640158/0x021B083C 0x01480158/' $CFG
    sed -i 's/0x021B0848 0x40403237/0x40403034/' $CFG
    sed -i 's/0x021B0850 0x40403C33/0x021B0850 0x40403A34/' $CFG
    sed -i 's/0x021B0018 0x00201740/0x021B0018 0x00211740/' $CFG
}
