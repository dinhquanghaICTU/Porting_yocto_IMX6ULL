#!/bin/sh

# Do not print into non-interactive SSH commands, SCP/SFTP or system services.
[ -t 1 ] || return 0 2>/dev/null || exit 0

uboot_version="U-Boot 2022.04-lf_v2022.04+g181859317bf (Nov 15 2022 - 06:28:05 +0000)"
model="$(tr -d '\000' </proc/device-tree/model 2>/dev/null)"
[ -n "$model" ] || model="i.MX6 ULL 14x14 EVK Board"

kernel="$(uname -r 2>/dev/null)"
hostname_value="$(hostname 2>/dev/null)"
cpu_model="$(awk -F: '/^model name|^Processor/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null)"
[ -n "$cpu_model" ] || cpu_model="NXP i.MX6ULL"

mem_total="$(awk '/^MemTotal:/ {printf "%.0f MiB", $2 / 1024}' /proc/meminfo 2>/dev/null)"
uptime_value="$(awk '{s=int($1); printf "%dd %02dh %02dm", s/86400, (s%86400)/3600, (s%3600)/60}' /proc/uptime 2>/dev/null)"

eth_ip="$(ip -4 -o addr show dev eth0 2>/dev/null | awk '{split($4, a, "/"); print a[1]; exit}')"
wifi_ip="$(ip -4 -o addr show dev wlan0 2>/dev/null | awk '{split($4, a, "/"); print a[1]; exit}')"
[ -n "$eth_ip" ] || eth_ip="not connected"
[ -n "$wifi_ip" ] || wifi_ip="not connected"

cmdline="$(cat /proc/cmdline 2>/dev/null)"
ota_slot="$(printf '%s\n' "$cmdline" | sed -n 's/.*ota\.slot=\([^ ]*\).*/\1/p')"
kernel_slot="$(printf '%s\n' "$cmdline" | sed -n 's/.*ota\.kernel_slot=\([^ ]*\).*/\1/p')"
rootfs_slot="$(printf '%s\n' "$cmdline" | sed -n 's/.*ota\.rootfs_slot=\([^ ]*\).*/\1/p')"
[ -n "$ota_slot" ] || ota_slot="unknown"
[ -n "$kernel_slot" ] || kernel_slot="unknown"
[ -n "$rootfs_slot" ] || rootfs_slot="unknown"

printf '\n'
case "$(tty 2>/dev/null)" in
    /dev/pts/*)
        # SSH/PTY terminals handle UTF-8 block characters correctly.
        cat /etc/banner-unicode
        ;;
    *)
        # UART/Minicom VT102: ASCII only, so byte width cannot corrupt lines.
        sed -n '1,13p' /etc/issue
        ;;
esac
printf '\n                    HNN OTA Embedded Device\n'
printf '               Ethernet | Wi-Fi | MQTT | OTA A/B\n\n'
printf '  +--------------------------------------------------------+\n'
printf '  |                  EMBEDDED OTA DEVICE                   |\n'
printf '  +--------------------------------------------------------+\n'
printf '  | %-10s : %-41s |\n' "Model" "$model"
printf '  | %-10s : %-41s |\n' "CPU" "$cpu_model"
printf '  | %-10s : %-41s |\n' "Memory" "$mem_total"
printf '  | %-10s : %-41s |\n' "Kernel" "$kernel"
printf '  | %-10s : %-41s |\n' "Hostname" "$hostname_value"
printf '  | %-10s : %-41s |\n' "Ethernet" "$eth_ip"
printf '  | %-10s : %-41s |\n' "Wi-Fi" "$wifi_ip"
printf '  | %-10s : A/B=%-3s kernel=%-3s rootfs=%-15s |\n' "OTA slots" "$ota_slot" "$kernel_slot" "$rootfs_slot"
printf '  | %-10s : %-41s |\n' "Uptime" "$uptime_value"
printf '  +--------------------------------------------------------+\n'
printf '  %s\n\n' "$uboot_version"

unset uboot_version model kernel hostname_value cpu_model mem_total
unset uptime_value eth_ip wifi_ip cmdline ota_slot kernel_slot rootfs_slot