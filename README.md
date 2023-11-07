# OVPNLogin
A simple auth-user-pass-verify program written in Go for use with a postgres database.

Examples of how to use it in a kubernetes cluster are provided in the examples directory.

The goal with this project was primary to create an application VPN for salt, but this could easily be modified for any application or just to be used as a standard vpn. The slim container is extremely lightweight:

```bash
/sbin/ip_real
/sbin/checkpath
/sbin/ip
/sbin/alive
/var/lib/openvpn/ovpn_login
/usr/sbin/openvpn
/usr/lib/libcap.so.2.69
/usr/lib/libdw-0.190.so
/usr/lib/libdrop_ambient.so.0.0.0
/usr/lib/iproute2/ematch_map
/usr/lib/iproute2/rt_realms
/usr/lib/iproute2/rt_tables
/usr/lib/iproute2/group
/usr/lib/iproute2/rt_dsfield
/usr/lib/iproute2/bpf_pinning
/usr/lib/iproute2/rt_scopes
/usr/lib/iproute2/rt_protos
/usr/lib/iproute2/nl_protos
/usr/lib/libasm-0.190.so
/usr/lib/liblzma.so.5.4.5
/usr/lib/libzstd.so.1.5.5
/usr/lib/liblzo2.so.2.0.0
/usr/lib/libfts.so.0.0.0
/usr/lib/liblz4.so.1.9.4
/usr/lib/ossl-modules/legacy.so
/usr/lib/libpsx.so.2.69
/usr/lib/libelf-0.190.so
/usr/lib/libcap-ng.so.0.0.0
/usr/lib/libmnl.so.0.2.0
/usr/lib/engines-3/padlock.so
/usr/lib/engines-3/loader_attic.so
/usr/lib/engines-3/capi.so
/usr/lib/engines-3/afalg.so
/usr/lib/libbz2.so.1.0.8
/etc/ssl/certs/ca-certificates.crt
/etc/passwd
/etc/group
/etc/hosts
/etc/hostname
/etc/resolv.conf
/run/.containerenv
/lib/sysctl.d/00-alpine.conf
/lib/libz.so.1.3
/lib/libcrypto.so.3
/lib/libssl.so.3
/lib/ld-musl-x86_64.so.1
```
