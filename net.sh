#!/bin/sh
# Needs to be run to initialize openvpn in the pod.
# If running in kubernetes, this can all be applied via a configmap & postStart script.
mkdir -p /dev/net || echo "error setting: mkdir -p /dev/net"
mknod /dev/net/tun c 10 200 || echo "error setting: mknod /dev/net/tun c 10 200"
chmod 600 /dev/net/tun || echo "error setting: chmod 600 /dev/net/tun"
chown openvpn:openvpn /dev/net/tun || echo "error setting: chown openvpn:openvpn /dev/net/tun"
modprobe tun || echo "error setting: modprobe tun"
echo "tun" >> /etc/modules-load.d/tun.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/ipv4.conf || echo "error setting: net.ipv4.ip_forward = 1"
echo "net.ipv4.conf.all.forwarding = 1" >> /etc/sysctl.d/ipv4.conf || echo "error setting: net.ipv4.conf.all.forwarding = 1" 