echo "Running OKM6ULL OTA boot script"


# U-Boot đã chạy lên RAM, init phần cứng cơ bản rồi đọc U-Boot environment
# từ vùng đã cấu hình bằng CONFIG_ENV_OFFSET/CONFIG_ENV_SIZE.
# boot_slot là biến legacy dùng từ thiết kế A/B ban đầu.
# Nếu máy mới flash hoặc env chưa có boot_slot thì mặc định chọn slot A.

#test là cú pháp của uboot sheel 

if test "${boot_slot}" = ""; then
    setenv boot_slot A
fi

# kernel_slot là slot kernel độc lập:
#   A -> load zImage_A
#   B -> load zImage_B
# Nếu env cũ chưa có kernel_slot thì lấy theo boot_slot để tương thích ngược.
if test "${kernel_slot}" = ""; then
    setenv kernel_slot ${boot_slot}
fi

# rootfs_slot là slot rootfs độc lập:
#   A -> root=/dev/mmcblk1p2
#   B -> root=/dev/mmcblk1p3
# Nếu env cũ chưa có rootfs_slot thì lấy theo boot_slot để tương thích ngược.
if test "${rootfs_slot}" = ""; then
    setenv rootfs_slot ${boot_slot}
fi

# upgrade_available là cờ báo đang có bản OTA vừa ghi xong nhưng Linux
# chưa xác nhận boot thành công. Khi cờ này bằng 1, U-Boot sẽ tăng ota_try
# để quyết định có rollback hay không.
if test "${upgrade_available}" = ""; then
    setenv upgrade_available 0
fi

# bootlimit giữ lại cho tương thích với cơ chế bootcount chuẩn của U-Boot.
# Board này bootcount không tự tăng đúng như mong muốn nên script dùng ota_try.
if test "${bootlimit}" = ""; then
    setenv bootlimit 3
fi

# altbootcmd là lệnh rollback dự phòng của U-Boot.
# ota_env_ready dùng để ép cập nhật lại altbootcmd khi format env thay đổi.
# Với thiết kế mới, kernel_slot và rootfs_slot được rollback riêng:
#   kernel_rollback_slot ưu tiên cho kernel
#   rootfs_rollback_slot ưu tiên cho rootfs
#   rollback_slot là biến cũ, chỉ dùng làm fallback
# Sau rollback sẽ tắt upgrade_available, reset bộ đếm thử boot, saveenv và reset.
if test "${ota_env_ready}" != "2"; then

    setenv altbootcmd '
        echo "OTA rollback";

        if test "${kernel_rollback_slot}" != ""; then
            setenv kernel_slot ${kernel_rollback_slot};
        else if test "${rollback_slot}" != ""; then
            setenv kernel_slot ${rollback_slot};
        else
            if test "${kernel_slot}" = "B"; then
                setenv kernel_slot A;
            else
                setenv kernel_slot B;
            fi;
        fi; fi;

        if test "${rootfs_rollback_slot}" != ""; then
            setenv rootfs_slot ${rootfs_rollback_slot};
        else if test "${rollback_slot}" != ""; then
            setenv rootfs_slot ${rollback_slot};
        else
            if test "${rootfs_slot}" = "B"; then
                setenv rootfs_slot A;
            else
                setenv rootfs_slot B;
            fi;
        fi; fi;

        setenv boot_slot ${rootfs_slot};
        setenv upgrade_available 0;
        setenv bootcount 0;
        setenv ota_try 0;
        saveenv;
        reset
    '

    setenv ota_env_ready 2
    saveenv
fi

# Khi đang có OTA pending, mỗi lần U-Boot chạy đến đây nghĩa là Linux chưa
# kịp xác nhận bản mới boot OK. Vì bootcount phần cứng/env không tăng ổn định
# trên board này, dùng ota_try làm bộ đếm thử boot.
# Nếu ota_try > 3 thì coi bản mới lỗi và rollback về slot đã lưu.
if test "${upgrade_available}" = "1"; then
    if test "${ota_try}" = ""; then
        setenv ota_try 0
    fi

    setexpr ota_try ${ota_try} + 1
    saveenv

    echo "OTA try ${ota_try}/3"

    if test ${ota_try} -gt 3; then
        echo "OTA rollback: boot failed too many times"

        # Rollback kernel về slot trước OTA. Nếu không có biến rollback mới,
        # dùng rollback_slot cũ. Nếu vẫn không có thì fallback an toàn về A.
        if test "${kernel_rollback_slot}" != ""; then
            setenv kernel_slot ${kernel_rollback_slot}
        else
            if test "${rollback_slot}" != ""; then
                setenv kernel_slot ${rollback_slot}
            else
                setenv kernel_slot A
            fi
        fi

        # Rollback rootfs về slot trước OTA. Tách riêng rootfs để tránh trường
        # hợp kernel tốt nhưng rootfs slot kia hỏng, hoặc ngược lại.
        if test "${rootfs_rollback_slot}" != ""; then
            setenv rootfs_slot ${rootfs_rollback_slot}
        else
            if test "${rollback_slot}" != ""; then
                setenv rootfs_slot ${rollback_slot}
            else
                setenv rootfs_slot A
            fi
        fi

        # boot_slot chỉ còn là biến legacy, đồng bộ theo rootfs_slot để các
        # script/công cụ cũ vẫn đọc được trạng thái rootfs hiện tại.
        setenv boot_slot ${rootfs_slot}
        setenv upgrade_available 0
        setenv bootcount 0
        setenv ota_try 0
        saveenv
        reset
    fi
else
    # Boot binh thuong khong ghi lai eMMC neu ota_try da bang 0.
    if test "${ota_try}" != "0"; then
        setenv ota_try 0
        saveenv
    fi
fi



# Mapping slot sang file/partition thật trên eMMC.
# Không dùng tên chung nếu có thể tránh được; boot rõ ràng theo slot:
#   kernel_slot=A -> /boot/zImage_A
#   kernel_slot=B -> /boot/zImage_B
#   rootfs_slot=A -> /dev/mmcblk1p2
#   rootfs_slot=B -> /dev/mmcblk1p3
# Slot nào khác A/B hoặc rỗng sẽ bị ép về A để tránh boot vào giá trị rác.
if test "${kernel_slot}" = "B"; then
    setenv ota_kernel zImage_B
else
    setenv kernel_slot A
    setenv ota_kernel zImage_A
fi

if test "${rootfs_slot}" = "B"; then
    setenv ota_root /dev/mmcblk1p3
else
    setenv rootfs_slot A
    setenv ota_root /dev/mmcblk1p2
fi

# Đồng bộ biến legacy boot_slot theo rootfs_slot sau khi đã normalize slot.
setenv boot_slot ${rootfs_slot}

echo "OTA boot kernel_slot=${kernel_slot} kernel=${ota_kernel} rootfs_slot=${rootfs_slot} root=${ota_root}"


# Load kernel từ boot partition FAT (/dev/mmcblk1p1).
# Ưu tiên file theo kernel_slot: zImage_A hoặc zImage_B.
# Nếu file theo slot không tồn tại thì fallback sang zImage để cứu các image cũ.
# Nếu cả zImage fallback cũng không có thì reset board.

if fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} ${ota_kernel}; then
    echo "Loaded ${ota_kernel}"
else
    echo "WARN: ${ota_kernel} not found, fallback to zImage"
    fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} zImage || reset
fi

# Load device tree. Ưu tiên DTB cho bản eMMC, fallback sang DTB EVK mặc định.
if fatload mmc ${mmcdev}:${mmcpart} ${fdt_addr} imx6ull-14x14-evk-emmc.dtb; then
    echo "Loaded imx6ull-14x14-evk-emmc.dtb"
else
    echo "WARN: emmc dtb not found, fallback to imx6ull-14x14-evk.dtb"
    fatload mmc ${mmcdev}:${mmcpart} ${fdt_addr} imx6ull-14x14-evk.dtb || reset
fi


# ota_rollback dùng khi bootz fail ngay trong U-Boot, ví dụ zImage sai format
# và kernel chưa chạy được. Khi đó Linux không có cơ hội tự xác nhận hay rollback.
# Lệnh này rollback kernel/rootfs theo biến rollback tương ứng rồi reset.
setenv ota_rollback 'echo "OTA rollback"; if test "${kernel_rollback_slot}" != ""; then setenv kernel_slot ${kernel_rollback_slot}; else if test "${rollback_slot}" != ""; then setenv kernel_slot ${rollback_slot}; else setenv kernel_slot A; fi; fi; if test "${rootfs_rollback_slot}" != ""; then setenv rootfs_slot ${rootfs_rollback_slot}; else if test "${rollback_slot}" != ""; then setenv rootfs_slot ${rollback_slot}; else setenv rootfs_slot A; fi; fi; setenv boot_slot ${rootfs_slot}; setenv upgrade_available 0; setenv bootcount 0; setenv ota_try 0; saveenv; reset'

# Truyền bootargs cho Linux:
#   console=...        UART log kernel
#   root=...           rootfs partition đã chọn
#   rootwait rw        đợi block device xuất hiện và mount read-write
#   ota.*              báo slot hiện tại cho app Linux đọc từ /proc/cmdline
#   panic=5            kernel panic thì tự reboot sau 5 giây
setenv bootargs console=${console},${baudrate} root=${ota_root} rootwait rw quiet loglevel=3 ota.slot=${rootfs_slot} ota.kernel_slot=${kernel_slot} ota.rootfs_slot=${rootfs_slot} panic=5

# Boot Linux bằng zImage và DTB đã load.
bootz ${loadaddr} - ${fdt_addr}

# Nếu bootz trả về thì kernel chưa chạy được. Khi đang OTA pending thì rollback
# ngay trong U-Boot; nếu không pending thì reset để thử lại theo env hiện tại.
echo "ERROR: bootz failed"
if test "${upgrade_available}" = "1"; then
    run ota_rollback
fi
reset