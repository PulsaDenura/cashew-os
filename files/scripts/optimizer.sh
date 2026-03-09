#!/usr/bin/env bash
set -oue pipefail

echo "Enforcing Lean Power Management Stack..."

# 1. Force the modern AMD P-State EPP driver (Safe for Intel too)
mkdir -p /usr/lib/bootc/kargs.d
cat <<EOF > /usr/lib/bootc/kargs.d/10-wayblue-power.toml
kargs = ["amd_pstate=active"]
EOF

# 2. Auto-switch PPD profile on power change
mkdir -p /usr/lib/udev/rules.d
cat <<EOF > /usr/lib/udev/rules.d/99-wayblue-powersave.rules
# Switch to Power Saver when unplugged
SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/bin/powerprofilesctl set power-saver"
# Switch to Balanced when plugged in
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/powerprofilesctl set balanced"
EOF

# 3. Low-overhead Sysctl Tweaks (Reduces CPU wakeups)
mkdir -p /usr/lib/sysctl.d
cat <<EOF > /usr/lib/sysctl.d/99-wayblue-power.conf
# Increase disk writeback time (saves disk wakeups)
vm.dirty_writeback_centisecs = 6000
# Disable NMI watchdog (saves CPU cycles)
kernel.nmi_watchdog = 0
# Laptop mode: minimize disk activity
vm.laptop_mode = 5
EOF

# 4. PowerTOP Auto-tune Service
echo "Setting up Powertop Auto-tune..."
cat <<EOF > /usr/lib/systemd/system/powertop-autotune.service
[Unit]
Description=Powertop autotune
After=multi-user.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 2
ExecStart=/usr/bin/powertop --auto-tune
# Keep USB HID (mice/kb) responsive to prevent lag
ExecStartPost=/bin/sh -c 'for f in \$(find /sys/bus/usb/drivers/usbhid -regex ".*/[0-9:.-]+" -printf "%f\n" | cut -d ":" -f 1 | sort -u); do echo on > "/sys/bus/usb/devices/\$f/power/control"; done'
RemainAfterExit=true
StandardOutput=null

[Install]
WantedBy=multi-user.target
EOF

# 5. Enable Services and mask potential conflicts
# We mask TuneD to ensure it never starts and eats RAM
# systemctl mask tuned.service
systemctl enable powertop-autotune.service
systemctl enable thermald.service
systemctl enable power-profiles-daemon.service

echo "Cashew-os optimization complete. All done."