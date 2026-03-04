#!/usr/bin/env bash
set -oue pipefail

echo "cloning autotiling script . ."
git clone https://github.com/nwg-piotr/autotiling /tmp/autotiling-repo
mv /tmp/autotiling-repo/autotiling/main.py /usr/bin/autotiling
chmod +x /usr/bin/autotiling
mkdir -p /etc/sway/config.d

echo "adding it to the sway configuration . ."
touch /etc/sway/config.d/99-autotiling.conf
echo "exec_always /usr/bin/autotiling" > /etc/sway/config.d/99-autotiling.conf

echo "autotiling installed, cleaning up . . "
rm -rf /tmp/autotiling-repo
