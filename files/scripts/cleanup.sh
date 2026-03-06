#!/usr/bin/env bash
set -euo pipefail

echo "cleaning up qterminal"
dnf remove qterminal -y
dnf remove thunar -y
dnf autoremove -y

echo "cleanup complete!"
