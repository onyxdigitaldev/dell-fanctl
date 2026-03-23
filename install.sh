#!/bin/bash
set -euo pipefail

# dell-fanctl installer
# Works on Fedora, Bazzite, Arch, Debian, and any distro with dell_smm_hwmon

RED='\033[0;31m'
GRN='\033[0;32m'
DIM='\033[2m'
RST='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

info()  { echo -e "${GRN}[+]${RST} $1"; }
warn()  { echo -e "${RED}[!]${RST} $1"; }
dim()   { echo -e "${DIM}    $1${RST}"; }

# ── Preflight ────────────────────────────────────────────

if [[ $EUID -ne 0 ]]; then
    warn "Run as root: sudo ./install.sh"
    exit 1
fi

# Load dell_smm_hwmon if not loaded
if ! lsmod | grep -q dell_smm_hwmon; then
    modprobe dell_smm_hwmon restricted=0 force=1 2>/dev/null || true
fi

# Check for dell_smm hwmon
DELL_HWMON=""
for d in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$d/name" 2>/dev/null)" = "dell_smm" ]; then
        DELL_HWMON="$d"
        break
    fi
done

if [ -z "$DELL_HWMON" ]; then
    warn "No dell_smm hwmon found"
    warn "This tool requires a Dell laptop with the dell_smm_hwmon kernel module"
    dim "Try: sudo modprobe dell_smm_hwmon restricted=0 force=1"
    exit 1
fi

if [ ! -f "$DELL_HWMON/pwm1" ]; then
    warn "dell_smm_hwmon loaded but no PWM control found at $DELL_HWMON/pwm1"
    warn "Your Dell model may not support userspace fan control"
    exit 1
fi

info "Found Dell SMM at $DELL_HWMON"

if ! python3 -c "pass" &>/dev/null; then
    warn "Python 3 not found"
    exit 1
fi

if ! python3 -c "import gi" &>/dev/null; then
    warn "python3-gobject not found (needed for tray applet)"
    dim "Fedora/Bazzite: sudo dnf install python3-gobject"
    dim "Arch:           sudo pacman -S python-gobject"
    dim "Debian/Ubuntu:  sudo apt install python3-gi"
    dim "The daemon will still work without it — only the tray applet needs GTK"
fi

# ── Install binaries ─────────────────────────────────────

info "Installing binaries to /usr/local/bin/"
install -m 755 "$SCRIPT_DIR/bin/dell-fanctl"      /usr/local/bin/
install -m 755 "$SCRIPT_DIR/bin/dell-fanctl-tray"  /usr/local/bin/

# ── Configure kernel module ──────────────────────────────

info "Configuring dell_smm_hwmon"
MODPROBE_CONF="/etc/modprobe.d/dell-fan.conf"
if [[ ! -f "$MODPROBE_CONF" ]] || ! grep -q "restricted=0" "$MODPROBE_CONF" 2>/dev/null; then
    echo "options dell_smm_hwmon restricted=0 force=1" > "$MODPROBE_CONF"
    dim "Created $MODPROBE_CONF"
else
    dim "Already configured"
fi

# ── Install systemd service ──────────────────────────────

info "Installing dell-fanctl service"
install -m 644 "$SCRIPT_DIR/systemd/dell-fanctl.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable dell-fanctl.service
dim "Service enabled (will start after reboot, or: sudo systemctl start dell-fanctl)"

# ── Tray autostart ───────────────────────────────────────

info "Installing tray autostart"
mkdir -p /etc/xdg/autostart
install -m 644 "$SCRIPT_DIR/systemd/dell-fanctl-tray.desktop" /etc/xdg/autostart/
dim "Tray applet will start on login for all users"

# ── Summary ──────────────────────────────────────────────

echo ""
info "Installation complete"
echo ""
dim "Files installed:"
dim "  /usr/local/bin/dell-fanctl           — adaptive fan daemon"
dim "  /usr/local/bin/dell-fanctl-tray      — system tray applet"
dim "  /etc/modprobe.d/dell-fan.conf        — dell_smm_hwmon config"
dim "  /etc/systemd/system/dell-fanctl.service"
dim "  /etc/xdg/autostart/dell-fanctl-tray.desktop"
echo ""
info "Start now: sudo systemctl start dell-fanctl"
