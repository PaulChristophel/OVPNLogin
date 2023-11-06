FROM golang:alpine AS builder
WORKDIR /usr/src/app
RUN apk upgrade --update --no-cache && apk add --update --no-cache make
# pre-copy/cache go.mod for pre-downloading dependencies and only redownloading them in subsequent builds if they change
#COPY go.mod go.sum ./
#RUN go mod download && go mod verify
COPY . .
RUN make upgrade && make build mode=prod

FROM docker.io/alpine/k8s:1.28.3 AS k8s

FROM alpine:edge AS app
COPY --from=k8s /usr/bin/kubectl /usr/bin/
RUN apk upgrade --update --no-cache && apk add --update --no-cache ca-certificates openvpn openssl iptables shadow
RUN usermod -d /var/lib/openvpn openvpn && apk del shadow
COPY net.sh /
RUN sh /net.sh
COPY /sbin/ip /sbin/ip_real
RUN mkdir -p /var/lib/openvpn/tmp
RUN chown -R openvpn:openvpn /var/lib/openvpn /var/log
ARG USER_ID=100
ARG GROUP_ID=101
USER ${USER_ID}:${GROUP_ID}
ENV OPENVPN=/var/lib/openvpn
ENV PATH=/var/lib/openvpn:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EXPOSE 1194/udp
EXPOSE 1194/tcp
COPY --from=builder /usr/src/app/bin/release/ovpn_login /var/lib/openvpn
COPY --from=builder /usr/src/app/bin/release/ip_fake /sbin/ip
COPY --from=builder /usr/src/app/bin/release/checkpath /sbin/checkpath
COPY --from=builder /usr/src/app/bin/release/alive /sbin/alive
ENTRYPOINT ["/usr/sbin/openvpn"]

# Easiest way to get the libraries we care about and nothing else
FROM alpine:edge AS slim-builder
RUN apk upgrade --update --no-cache && apk add --update --no-cache ca-certificates openvpn

FROM scratch as slim
COPY --from=app /etc/passwd /etc/passwd
COPY --from=app /etc/group /etc/group
COPY --from=app --chown=100:101 /var/lib/openvpn /var/lib/openvpn
COPY --from=app --chown=100:101 /var/log /var/log
COPY --from=slim-builder /usr/sbin/openvpn /usr/sbin/openvpn
COPY --from=slim-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# COPY LIBS
COPY --from=slim-builder /lib /lib
# COPY USR LIBS
COPY --from=slim-builder /usr/lib /usr/lib
COPY --from=builder /usr/src/app/bin/release/ip_fake /sbin/ip
COPY --from=builder /usr/src/app/bin/release/checkpath /sbin/checkpath
COPY --from=builder /usr/src/app/bin/release/alive /sbin/alive
COPY --from=app --chown=100:101 /tmp /tmp
ARG USER_ID=100
ARG GROUP_ID=101
USER ${USER_ID}:${GROUP_ID}
ENV OPENVPN=/var/lib/openvpn
ENV PATH=/var/lib/openvpn:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EXPOSE 1194/udp
EXPOSE 1194/tcp
ENTRYPOINT ["/usr/sbin/openvpn"]
