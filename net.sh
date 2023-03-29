#!/bin/sh
# Needs to be run to initialize openvpn in the pod.
# If running in kubernetes, this can all be applied via a configmap & postStart script.
mkdir -p /dev/net
mknod /dev/net/tun c 10 200 || true # exit for podman. We will need this to run later
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/ipv4.conf
echo "net.ipv4.conf.all.forwarding = 1" >> /etc/sysctl.d/ipv4.conf
modprobe tun || true # exit for podman. We will need this to run later
echo "tun" >> /etc/modules-load.d/tun.conf