#!/bin/sh
# Needs to be run to initialize openvpn in the pod.
# If running in kubernetes, this can all be applied via a configmap & postStart script.
set +e
mkdir -p /dev/net || echo "error setting: mkdir -p /dev/net"
mknod /dev/net/tun c 10 200 || echo "error setting: mknod /dev/net/tun c 10 200"
chmod 600 /dev/net/tun || echo "error setting: chmod 600 /dev/net/tun"
chown openvpn:openvpn /dev/net/tun || echo "error setting: chown openvpn:openvpn /dev/net/tun"
modprobe tun || echo "error setting: modprobe tun"
echo "tun" >> /etc/modules-load.d/tun.conf
cat << 'EOF' | tee /etc/sysctl.d/ipv4.conf || echo "error setting: tee /etc/sysctl.d/ipv4.conf"
# Enable IP forwarding
net.ipv4.ip_forward=1

# Disable ICMP redirect acceptance
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0

# Disable ICMP redirect sending
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# Enable strict reverse path filtering
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Enable SYN cookies
net.ipv4.tcp_syncookies=1
EOF
