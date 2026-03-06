#!/usr/bin/env bash
set -oue pipefail

echo "Setting up Powertop Auto-tune..."
# Create the service file
cat <<EOF > /usr/lib/systemd/system/powertop-autotune.service
[Unit]
Description=Powertop autotune
After=power-profiles-daemon.service

[Service]
Type=oneshot
# Adding a short sleep ensures hardware is fully initialized
ExecStartPre=/usr/bin/sleep 3
ExecStart=/usr/bin/powertop --auto-tune
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Enable the new service
systemctl enable powertop-autotune.service
echo "Optimization complete."



rm -rf /etc/skel/.config/pcmanfm-qt
echo "all done"
