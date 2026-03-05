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

# Download autocpu-freq
# mkdir /tmp/auto-cpufreq
# cd /tmp/auto-cpufreq
# git clone https://github.com/AdnanHodzic/auto-cpufreq.git
# echo "downloaded autocpu-freq to home directory"
