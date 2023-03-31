FROM golang:alpine AS builder
WORKDIR /usr/src/app
RUN apk upgrade --update --no-cache && apk add --update --no-cache make
# pre-copy/cache go.mod for pre-downloading dependencies and only redownloading them in subsequent builds if they change
#COPY go.mod go.sum ./
#RUN go mod download && go mod verify
COPY . .
RUN make upgrade && make build mode=prod

FROM alpine/k8s:1.26.3 AS k8s

FROM alpine:edge AS app
COPY --from=k8s /usr/bin/kubectl /usr/bin/
RUN apk upgrade --update --no-cache && apk add --update --no-cache ca-certificates openvpn openssl iptables shadow
RUN usermod -d /var/lib/openvpn openvpn && apk del shadow
COPY net.sh /
RUN sh /net.sh
RUN mkdir -p /var/lib/openvpn/tmp
RUN chown openvpn:openvpn /var/lib/openvpn /var/log
ARG USER_ID=100
USER ${USER_ID}
ENV OPENVPN=/var/lib/openvpn
ENV PATH=/var/lib/openvpn:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EXPOSE 1194/udp
EXPOSE 1194/tcp
COPY --from=builder /usr/src/app/bin/release/ovpn_login /var/lib/openvpn
ENTRYPOINT ["/usr/sbin/openvpn"]
