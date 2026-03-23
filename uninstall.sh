#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
DIM='\033[2m'
RST='\033[0m'

info()  { echo -e "${GRN}[+]${RST} $1"; }
dim()   { echo -e "${DIM}    $1${RST}"; }

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!]${RST} Run as root: sudo ./uninstall.sh"
    exit 1
fi

info "Stopping services"
systemctl stop dell-fanctl.service 2>/dev/null || true
systemctl disable dell-fanctl.service 2>/dev/null || true

info "Restoring BIOS fan control"
for d in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$d/name" 2>/dev/null)" = "dell_smm" ]; then
        echo 0 > "$d/pwm1" 2>/dev/null || true
        break
    fi
done

info "Removing files"
rm -f /usr/local/bin/dell-fanctl
rm -f /usr/local/bin/dell-fanctl-tray
rm -f /etc/systemd/system/dell-fanctl.service
rm -f /etc/xdg/autostart/dell-fanctl-tray.desktop
rm -f /tmp/dell-fanctl.state
rm -f /tmp/dell-fanctl.force

systemctl daemon-reload

echo ""
info "Uninstalled. Module config left for manual cleanup:"
dim "  /etc/modprobe.d/dell-fan.conf"
