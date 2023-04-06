# Kubernetes configs
These examples demonstrate a basic application VPN use case, which can be easily adapted to implement a full VPN. The configurations are based on this guide for running OpenVPN within an unprivileged container: https://community.openvpn.net/openvpn/wiki/UnprivilegedUser#RunOpenVPNwithinunprivilegedpodmancontainer. In this setup, privileged operations are executed by the init containers, while the actual service is run by the udp/tcp containers, which drop all privileges.

Clients use OpenVPN to access specific services within the Kubernetes cluster that are not intended to be available to the world (e.g., https://docs.saltproject.io/en/latest/topics/hardening.html).

To use this example, replace instances of **SERVICENAME** with the actual service name and **FAKEIP** with the IP address that clients will connect to. The example is designed for a "hub-and-spoke" configuration, where multiple instances of **SERVICENAME** run in different namespaces for different customers using different node ports.

Additionally, you will need to provide certificate information in the configmap and secret YAML files.

Since the original use case is for SaltStack, an example Salt grain is also provided.