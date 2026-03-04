#!/usr/bin/env bash
set -euo pipefail

echo "Applying security hardening..."

# --- 1. Networking: MAC Randomization ---
# Makes your device harder to track across different Wi-Fi networks.
mkdir -p /etc/NetworkManager/conf.d
cat <<EOF > /etc/NetworkManager/conf.d/00-macrandomize.conf
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF

# --- 2. Networking: Network Time Security (NTS) ---
# Encrypts time synchronization to prevent MITM attacks on your system clock.
if [ -f /etc/chrony.conf ]; then
    sed -i 's/^pool.*/pool time.cloudflare.com iburst nts/' /etc/chrony.conf
    echo "ntsdumpdir /var/lib/chrony" >> /etc/chrony.conf
fi

# --- 3. Privacy: Disable Coredumps ---
# Prevents sensitive RAM data from being written to disk if an app crashes.
mkdir -p /etc/systemd/coredump.conf.d
cat <<EOF > /etc/systemd/coredump.conf.d/disable.conf
[Coredump]
Storage=none
ProcessSizeMax=0
EOF

# --- 4. Attack Surface: Module Blacklisting ---
# Disables drivers for obsolete or rare hardware to shrink kernel attack surface.
cat <<EOF > /etc/modprobe.d/blacklist-unused.conf
blacklist floppy
blacklist parport
blacklist parport_pc
blacklist firewire-core
EOF

# --- 5. Auth: Hardened Password Hashing ---
# Uses 'yescrypt' with a cost factor of 7 (Exponentially harder to crack).
sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD YESCRYPT/' /etc/login.defs
echo "YESCRYPT_COST_FACTOR 7" >> /etc/login.defs

# --- 6. Auth: 24h Brute Force Lockout ---
# Locks account for 24 hours after 50 failed attempts.
echo "deny = 50" >> /etc/security/faillock.conf
echo "unlock_time = 86400" >> /etc/security/faillock.conf

echo "Hardening complete!"

# --- 7. Configure systemd-resolved for DNS-over-TLS using Cloudflare and Quad9
mkdir -p /etc/systemd/resolved.conf.d
cat <<EOF > /etc/systemd/resolved.conf.d/privacy.conf
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
DNSOverTLS=yes
DNSSEC=yes
FallbackDNS=1.0.0.1#cloudflare-dns.com
EOF
