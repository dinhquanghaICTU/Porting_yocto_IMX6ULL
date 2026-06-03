echo "Running OKM6ULL OTA boot script"


#sau khi uboot được load lên ram rồi thì nó sẽ innit cho một số ngoại vi
#sau khi song nó sẽ đoc vùng CONFIG_ENV_SIZE=0x2000,CONFIG_ENV_OFFSET=0x400000
#mà mình  config từ trước để nó đọc các biến môi trường trong đó có biến boot_slot
# chỗ này là chỗ gán lại khi ,mới khởi động lần đầu chưa có boot slot thì sẽ set mặc định là A
if test "${boot_slot}" = ""; then
    setenv boot_slot A
fi

#tạo thêm biến upgrade_available để làm cờ Đang có bản OTA mới vừa ghi xong
#và chưa được xác nhận boot OK. U-Boot bắt đầu quan tâm bootcount.
if test "${upgrade_available}" = ""; then
    setenv upgrade_available 0
fi

#bootlimit là giới hạn số lần U-Boot cho phép thử boot khi đang có update pending.
if test "${bootlimit}" = ""; then
    setenv bootlimit 3
fi

#in log "OTA rollback"
#nếu đang boot B lỗi thì đổi về A
#nếu đang boot A lỗi thì đổi về B
#tắt cờ upgrade_available
#reset bootcount
#lưu env xuống eMMC
#reset board

if test "${ota_env_ready}" != "1"; then
    setenv altbootcmd 'echo "OTA rollback"; if test "${boot_slot}" = "B"; then setenv boot_slot A; else setenv boot_slot B; fi; setenv upgrade_available 0; setenv bootcount 0; saveenv; reset'
    setenv ota_env_ready 1
    saveenv
fi

#tu dem so lan thu boot ban OTA moi.
#vi bootcount cua U-Boot tren board nay khong tang nen dung ota_try de tu rollback.
#neu upgrade_available=1 ma boot loi lap lai qua 3 lan thi quay ve rollback_slot.
if test "${upgrade_available}" = "1"; then
    if test "${ota_try}" = ""; then
        setenv ota_try 0
    fi

    setexpr ota_try ${ota_try} + 1
    saveenv

    echo "OTA try ${ota_try}/3"

    if test ${ota_try} -gt 3; then
        echo "OTA rollback: boot failed too many times"

        if test "${rollback_slot}" != ""; then
            setenv boot_slot ${rollback_slot}
        else
            setenv boot_slot A
        fi

        setenv upgrade_available 0
        setenv bootcount 0
        setenv ota_try 0
        saveenv
        reset
    fi
else
    setenv ota_try 0
    saveenv
fi


#Slot A:
#  kernel: zImage_A
#  rootfs: /dev/mmcblk1p2

#Slot B:
#  kernel: zImage_B
#  rootfs: /dev/mmcblk1p3

if test "${boot_slot}" = "B"; then
    setenv ota_kernel zImage_B
    setenv ota_root /dev/mmcblk1p3
else
    setenv boot_slot A
    setenv ota_kernel zImage_A
    setenv ota_root /dev/mmcblk1p2
fi

echo "OTA boot slot=${boot_slot} kernel=${ota_kernel} root=${ota_root}"


 #lấy kernel theo slot hiện tại trước. Nếu đang chọn slot A
 #thì lấy zImage_A, nếu slot B thì lấy zImage_B. Lấy được thì báo là đã load xong.
 #Nếu không tìm thấy file đó, ví dụ không có zImage_A hoặc zImage_B, thì đừng chết ngay. Thử lấy kernel mặc định tên zImage.
 #Nếu đến cả zImage cũng không có thì hết đường boot, reset lại board.”

if fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} ${ota_kernel}; then
    echo "Loaded ${ota_kernel}"
else
    echo "WARN: ${ota_kernel} not found, fallback to zImage"
    fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} zImage || reset
fi

if fatload mmc ${mmcdev}:${mmcpart} ${fdt_addr} imx6ull-14x14-evk-emmc.dtb; then
    echo "Loaded imx6ull-14x14-evk-emmc.dtb"
else
    echo "WARN: emmc dtb not found, fallback to imx6ull-14x14-evk.dtb"
    fatload mmc ${mmcdev}:${mmcpart} ${fdt_addr} imx6ull-14x14-evk.dtb || reset
fi


#set command line cho Linux kernel như này: log ra UART nào, rootfs nằm ở đâu,
#đợi rootfs xuất hiện,mount read-write, và báo cho Linux biết đang boot slot A hay B.

setenv ota_rollback 'echo "OTA rollback"; if test "${rollback_slot}" != ""; then setenv boot_slot ${rollback_slot}; else setenv boot_slot A; fi; setenv upgrade_available 0; setenv bootcount 0; setenv ota_try 0; saveenv; reset'

setenv bootargs console=${console},${baudrate} root=${ota_root} rootwait rw ota.slot=${boot_slot} panic=5

bootz ${loadaddr} - ${fdt_addr}

echo "ERROR: bootz failed"
if test "${upgrade_available}" = "1"; then
    run ota_rollback
fi
reset