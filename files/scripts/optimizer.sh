#!/usr/bin/env bash
set -oue pipefail

echo "Setting up Powertop Auto-tune..."
# Create the service file
cat <<EOF > /usr/lib/systemd/system/powertop-autotune.service
[Unit]
Description=Powertop autotune
After=multi-user.target

[Service]
Type=oneshot
# Adding a short sleep ensures hardware is fully initialized
ExecStartPre=/usr/bin/sleep 2
ExecStart=/usr/bin/powertop --auto-tune
ExecStartPost=/bin/sh -c 'for f in $(find /sys/bus/usb/drivers/usbhid -regex ".*/[0-9:.-]+" -printf "%f\n" | cut -d ":" -f 1 | sort -u); do echo on > "/sys/bus/usb/devices/$f/power/control"; done'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Enable the new service
systemctl enable powertop-autotune.service
echo "Optimization complete."

echo "all done"
