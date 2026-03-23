# dell-fanctl

Adaptive fan controller for Dell laptops. Automatically switches between quiet and gaming fan curves based on CPU load and temperature — no manual intervention needed.

Uses the `dell_smm_hwmon` kernel module for direct PWM fan control. Tested on the Latitude 5400 but should work on any Dell laptop that exposes `pwm1` via `dell_smm_hwmon`.

## How it works

`dell-fanctl` monitors CPU utilization by reading `/proc/stat` every 3 seconds and reads CPU package temperature from `coretemp`. It maintains two PWM curves — quiet and gaming — and interpolates fan speed based on the active curve and current temperature.

**Hysteresis prevents thrashing:**
- Gaming mode engages after **12 seconds** of sustained >55% CPU
- Quiet mode re-engages after **30 seconds** of sustained <25% CPU
- Counter decay (not hard reset) absorbs transient spikes and dips

The asymmetry is deliberate — ramp up fast to protect thermals, ramp down slow to survive loading screens.

**Temperature-driven PWM:**
- Quiet curve: fan off below 50C, ramps to full at 85C
- Gaming curve: fan starts at 40C, full blast at 72C

On shutdown, PWM is set to 0 (BIOS auto control restored).

## Components

| File | Purpose |
|------|---------|
| `dell-fanctl` | Adaptive fan daemon (Python 3, zero deps) |
| `dell-fanctl-tray` | System tray applet (GTK3 + AppIndicator3) |

The tray applet shows a **purple Q** in quiet mode and a **blue G** in gaming mode. Right-click for manual override — forced profile sticks until CPU load naturally triggers the opposite transition.

## Requirements

- A Dell laptop with `dell_smm_hwmon` kernel module and `pwm1` control
- Python 3.10+
- `python3-gobject` + `libappindicator-gtk3` (for tray applet only)

## Install

```bash
git clone <this-repo>
cd dell-fanctl
sudo ./install.sh
sudo systemctl start dell-fanctl
```

The installer:
1. Copies binaries to `/usr/local/bin/`
2. Configures `dell_smm_hwmon` with `restricted=0 force=1` via modprobe
3. Installs and enables the systemd service
4. Sets up tray applet autostart

### Immutable distros (Bazzite, Silverblue, etc.)

All files go to `/usr/local/` and `/etc/`, which persist across updates. No packages to layer — the daemon is pure Python stdlib and the tray uses pre-installed GTK3 bindings.

## PWM Curves

Edit the `CURVE_QUIET` and `CURVE_GAMING` lists in `/usr/local/bin/dell-fanctl` to adjust the temperature-to-PWM mapping. Each entry is `(temp_celsius, pwm_value)` with linear interpolation between points.

Note: Most Dell laptops map PWM values to a few discrete fan speed steps rather than linear RPM. Test with different values to find the effective steps for your model.

## Checking your Dell's compatibility

```bash
# Load the module
sudo modprobe dell_smm_hwmon restricted=0 force=1

# Find the hwmon device
for d in /sys/class/hwmon/hwmon*; do
    [ "$(cat $d/name 2>/dev/null)" = "dell_smm" ] && echo "$d" && break
done

# Check for PWM control
ls /sys/class/hwmon/hwmon*/pwm1 2>/dev/null

# Test a write (sets fan to ~50%)
echo 128 | sudo tee /sys/class/hwmon/hwmon*/pwm1

# Restore BIOS control
echo 0 | sudo tee /sys/class/hwmon/hwmon*/pwm1
```

## Uninstall

```bash
sudo ./uninstall.sh
```

## License

MIT
