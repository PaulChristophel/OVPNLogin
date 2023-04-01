# Kubernetes configs
These examples provide a simple use case of an application vpn.
Clients run openvpn to gain access to a particular service within the kubernetes cluster
that isn't necessarily something that you'd want open to the world. (For instance, https://docs.saltproject.io/en/latest/topics/hardening.html)

This example requires replacing instances of **SERVICENAME** with the service name and **FAKEIP** with the IP address that clients will "connect" to. It is written for a "hub-and-spoke" instance. (i.e. It assumes you have multiple copies of **SERVICENAME** running in different namespaces for different customers on different nodeports.)

Certificate information also needs to be provided in the configmap and secret yaml files.

Since the orignal use case is for salt, an example grain is provided.
