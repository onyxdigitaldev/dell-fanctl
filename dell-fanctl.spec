Name:           dell-fanctl
Version:        1.0.0
Release:        1%{?dist}
Summary:        Adaptive fan controller for Dell laptops
License:        MIT
URL:            https://github.com/onyxdigitaldev/dell-fanctl
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  systemd-rpm-macros
Requires:       python3 >= 3.10
Recommends:     python3-gobject
Recommends:     libappindicator-gtk3

%description
Adaptive fan controller for Dell laptops. Automatically switches between
quiet and gaming fan curves based on CPU load and temperature. Uses
dell_smm_hwmon for direct PWM fan control.

Features:
- Temperature-driven PWM curves with linear interpolation
- Hysteresis with asymmetric thresholds prevents profile thrashing
- System tray applet with manual override
- Clean shutdown restores BIOS fan control

%prep
%setup -q

%install
install -Dm 755 bin/dell-fanctl %{buildroot}%{_bindir}/dell-fanctl
install -Dm 755 bin/dell-fanctl-tray %{buildroot}%{_bindir}/dell-fanctl-tray
install -Dm 644 systemd/dell-fanctl.service %{buildroot}%{_unitdir}/dell-fanctl.service
install -Dm 644 systemd/dell-fanctl-tray.desktop %{buildroot}%{_sysconfdir}/xdg/autostart/dell-fanctl-tray.desktop

%post
if [ ! -f /etc/modprobe.d/dell-fan.conf ] || ! grep -q "restricted=0" /etc/modprobe.d/dell-fan.conf 2>/dev/null; then
    mkdir -p /etc/modprobe.d
    echo "options dell_smm_hwmon restricted=0 force=1" > /etc/modprobe.d/dell-fan.conf
fi
%systemd_post dell-fanctl.service

%preun
%systemd_preun dell-fanctl.service

%postun
# Restore BIOS fan control
for d in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$d/name" 2>/dev/null)" = "dell_smm" ]; then
        echo 0 > "$d/pwm1" 2>/dev/null || true
        break
    fi
done
%systemd_postun_with_restart dell-fanctl.service

%files
%license LICENSE
%doc README.md
%{_bindir}/dell-fanctl
%{_bindir}/dell-fanctl-tray
%{_unitdir}/dell-fanctl.service
%{_sysconfdir}/xdg/autostart/dell-fanctl-tray.desktop

%changelog
* Mon Mar 23 2026 Onyx Digital <dev@onyxdigital.dev> - 1.0.0-1
- Initial release
