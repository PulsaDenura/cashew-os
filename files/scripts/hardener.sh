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
# FIXED: Using 'server' instead of 'pool' for robust NTS enforcement.
if [ -f /etc/chrony.conf ]; then
    # Comment out existing pools/servers to avoid conflicts
    sed -i 's/^\(pool\|server\)/# \1/' /etc/chrony.conf
    mkdir -p /var/lib/chrony
    # Append trusted NTS servers
    cat <<EOF >> /etc/chrony.conf
server time.cloudflare.com iburst nts
server nts.netnod.se iburst nts
server ptbtime1.ptb.de iburst nts
ntsdumpdir /var/lib/chrony
EOF
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
echo "Disable uncommon filesystem drivers to reduce kernel attack surface . ."

cat <<EOF > /etc/modprobe.d/blacklist-unused.conf
blacklist floppy
blacklist parport
blacklist parport_pc
blacklist firewire-core
EOF

# Disable uncommon filesystem drivers to reduce kernel attack surface
cat <<EOF > /etc/modprobe.d/cis-filesystems.conf
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install udf /bin/true
EOF

# Disable obscure networking protocols
cat <<EOF > /etc/modprobe.d/cis-network.conf
install sctp /bin/true
install dccp /bin/true
install rds /bin/true
install tipc /bin/true
EOF


# --- 5. Auth: Hardened Password Hashing ---
# Uses 'yescrypt' with a cost factor of 6 (Exponentially harder to crack).
sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD YESCRYPT/' /etc/login.defs
echo "YESCRYPT_COST_FACTOR 6" >> /etc/login.defs

# --- 6. Auth: 24h Brute Force Lockout ---
# Locks account for 24 hours after 50 failed attempts.
echo "deny = 50" >> /etc/security/faillock.conf
echo "unlock_time = 86400" >> /etc/security/faillock.conf

# --- 7. Network
cat <<EOF > /etc/sysctl.d/60-network-hardening.conf
# Ignore ICMP redirects and 'Source Routed' packets (these are almost always malicious)
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
EOF


# --- 7. Configure systemd-resolved for DNS-over-TLS using Cloudflare and Quad9
echo "Configure systemd-resolved for DNS-over-TLS using Cloudflare and Quad9 . . "
mkdir -p /etc/systemd/resolved.conf.d
cat <<EOF > /etc/systemd/resolved.conf.d/privacy.conf
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
DNSOverTLS=yes
DNSSEC=allow-downgrade
FallbackDNS=1.0.0.1#cloudflare-dns.com
EOF







echo "Hardening complete!"
