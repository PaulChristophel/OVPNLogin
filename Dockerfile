ARG GOLANG_IMAGE=docker.io/library/golang:alpine
ARG K8S_IMAGE=docker.io/alpine/k8s:1.36.2
ARG ALPINE_IMAGE=docker.io/library/alpine:3.24.1
ARG OPENVPN_VERSION=2.7.6
ARG OPENVPN_SHA512=2e45d147f0983b6f343b6772c20b17e67bff0143e7bcf3c2a10551b77d9929c64c86e53b4ade5493023517f3ccd92b0c1011d03cb3543321d0f9faea408e6020

FROM ${GOLANG_IMAGE} AS builder
ARG GOLANGCI_LINT_VERSION=v2.12.2
WORKDIR /usr/src/app
RUN apk upgrade --update --no-cache && apk add --update --no-cache curl make
RUN curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b "$(go env GOPATH)/bin" "${GOLANGCI_LINT_VERSION}"
# pre-copy/cache go.mod for pre-downloading dependencies and only redownloading them in subsequent builds if they change
#COPY go.mod go.sum ./
#RUN go mod download && go mod verify
COPY . .
RUN make upgrade && make build mode=prod

FROM ${K8S_IMAGE} AS k8s

FROM ${ALPINE_IMAGE} AS openvpn-build
ARG OPENVPN_VERSION
ARG OPENVPN_SHA512
WORKDIR /usr/src/openvpn
RUN apk upgrade --update --no-cache && apk add --update --no-cache \
		build-base \
		ca-certificates \
		curl \
		libcap-ng-dev \
		libnl3-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		lzo-dev \
		openssl-dev \
		pkcs11-helper-dev \
		tar
RUN curl -fsSLO "https://build.openvpn.net/downloads/releases/openvpn-${OPENVPN_VERSION}.tar.gz" \
	&& echo "${OPENVPN_SHA512}  openvpn-${OPENVPN_VERSION}.tar.gz" | sha512sum -c - \
	&& tar -xzf "openvpn-${OPENVPN_VERSION}.tar.gz" --strip-components=1
RUN ./configure \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--sysconfdir=/etc/openvpn \
		--enable-dco \
		--enable-pkcs11 \
		--disable-dns-updown-by-default \
	&& make -j"$(nproc)" \
	&& make DESTDIR=/openvpn-install install \
	&& strip /openvpn-install/usr/sbin/openvpn \
	&& find /openvpn-install -name '*.a' -delete \
	&& find /openvpn-install -name '*.la' -delete \
	&& rm -rf /openvpn-install/usr/include /openvpn-install/usr/lib/pkgconfig /openvpn-install/usr/share

FROM ${ALPINE_IMAGE} AS app
ARG USER_ID=10001
ARG GROUP_ID=10001
COPY --from=k8s /usr/bin/kubectl /usr/bin/
COPY --from=openvpn-build /openvpn-install/ /
RUN apk upgrade --update --no-cache && apk add --update --no-cache \
		ca-certificates \
		iproute2-minimal \
		iptables \
		libcap-ng \
		libnl3 \
		linux-pam \
		lz4-libs \
		lzo \
		openssl \
		pkcs11-helper \
	&& addgroup -S -g ${GROUP_ID} openvpn \
	&& adduser -S -D -H -h /var/lib/openvpn -s /sbin/nologin -G openvpn -u ${USER_ID} openvpn
COPY net.sh /
RUN sh /net.sh && cp /sbin/ip /sbin/ip_real
RUN mkdir -p /var/lib/openvpn/tmp
RUN chown -R ${USER_ID}:${GROUP_ID} /var/lib/openvpn /var/log
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

FROM ${ALPINE_IMAGE} AS slim-builder
RUN apk upgrade --update --no-cache && apk add --update --no-cache \
		ca-certificates \
		iproute2-minimal \
		libcap-ng \
		libnl3 \
		linux-pam \
		lz4-libs \
		lzo \
		openssl \
		pkcs11-helper \
	&& rm -rf /lib/apk /lib/libapk*
COPY --from=openvpn-build /openvpn-install/ /

FROM scratch as slim
ARG USER_ID=10001
ARG GROUP_ID=10001
COPY --from=app /etc/passwd /etc/passwd
COPY --from=app /etc/group /etc/group
COPY --from=app --chown=${USER_ID}:${GROUP_ID} /var/lib/openvpn /var/lib/openvpn
COPY --from=app --chown=${USER_ID}:${GROUP_ID} /var/log /var/log
COPY --from=slim-builder /usr/sbin/openvpn /usr/sbin/openvpn
COPY --from=slim-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# COPY LIBS
COPY --from=slim-builder /lib /lib
# COPY USR LIBS
COPY --from=slim-builder /usr/lib /usr/lib
COPY --from=app /sbin/ip_real /sbin/ip_real
COPY --from=builder /usr/src/app/bin/release/ip_fake /sbin/ip
COPY --from=builder /usr/src/app/bin/release/checkpath /sbin/checkpath
COPY --from=builder /usr/src/app/bin/release/alive /sbin/alive
COPY --from=app --chown=${USER_ID}:${GROUP_ID} /tmp /tmp
USER ${USER_ID}:${GROUP_ID}
ENV OPENVPN=/var/lib/openvpn
ENV PATH=/var/lib/openvpn:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EXPOSE 1194/udp
EXPOSE 1194/tcp
ENTRYPOINT ["/usr/sbin/openvpn"]
