# Contributing

Contributions that improve OVPNLogin, the OpenVPN container images, the Helm
chart, documentation, or release automation are welcome.

## Before making a change

Open an issue before changing authentication behavior, supported OpenVPN
versions, image variants, the Helm chart's public values, or release behavior.
Focused bug fixes and documentation improvements can go directly to a pull
request.

Keep changes scoped to this repository's purpose: providing the OVPNLogin
authentication helper and OpenVPN container images for Kubernetes deployments.
The `app` and `slim` targets must continue to provide compatible OpenVPN and
OVPNLogin behavior even though their runtime contents differ.

## Repository layout

- `images.json` is the source of truth for the image repository, OpenVPN
  release and checksum, build images, Alpine runtime version, and image
  variants.
- `Dockerfile` builds OVPNLogin and OpenVPN, then produces the `app` and `slim`
  image targets.
- `.github/workflows/unstable.yaml` builds and publishes both image variants.
- `openvpn-router/` contains the Helm chart.
- `example/` contains standalone Kubernetes examples.

When updating OpenVPN, update both its version and SHA-512 checksum in
`images.json`. Verify the checksum against the downloaded upstream release;
never bypass or weaken the checksum check in the Dockerfile.

Keep `build.alpine_version` synchronized with the tag in
`build.alpine_image`. If an image variant, runtime base, or component version
changes, update the corresponding OCI annotations and image labels in the
publishing workflow. The two metadata lists intentionally match so registry
overviews and image configuration inspection report the same facts.

Published builds retain immutable commit-SHA tags and also receive OpenVPN
version tags:

- `app`: `<openvpn-version>` and `sha-<commit>`
- `slim`: `slim-<openvpn-version>` and `slim-sha-<commit>`

Do not add metadata for components or capabilities that are not present in the
selected target.

## Local validation

Run the Go tests and linter after changing Go code:

```sh
GOCACHE=/tmp/ovpnlogin-gocache \
  /opt/homebrew/opt/go/bin/go test ./...

GOLANGCI_LINT_CACHE=/tmp/ovpnlogin-golangci-cache \
  /Users/pmartin47/go/bin/golangci-lint run
```

`make upgrade` updates module dependencies and rewrites `go.mod` and `go.sum`.
Run it only when a dependency upgrade is intentional.

Build both container targets with Podman after changing the Dockerfile,
OpenVPN version, build images, or runtime dependencies:

```sh
make podman
```

This produces the versioned and convenience tags defined by the Makefile. A
successful build verifies compilation and image assembly; it does not publish
anything. Do not run `make podman-push` unless publication is explicitly
intended and authorized.

For Helm chart changes, lint and render the chart:

```sh
/opt/homebrew/bin/helm lint ./openvpn-router \
  --set certificate.enabled=false
/opt/homebrew/bin/helm template openvpn-router ./openvpn-router \
  --set certificate.enabled=false >/tmp/openvpn-router.yaml
```

Run configuration and whitespace checks for all changes:

```sh
/opt/homebrew/bin/python3.14 -m json.tool images.json >/dev/null
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/unstable.yaml")'
/opt/homebrew/bin/git diff --check
```

If you run `make helm`, review the generated chart archives separately and do
not include old `.tgz` packages in an unrelated pull request.

## Pull requests

In the pull request description:

- explain the problem and intended behavior;
- identify whether Go code, the `app` image, the `slim` image, or the Helm chart
  is affected;
- list the validation commands run and their results; and
- call out anything that could not be tested locally, including image
  publication or registry metadata inspection.

Keep unrelated changes in separate pull requests. Changes to shared OpenVPN or
OVPNLogin behavior should be validated against both image targets. Changes to
published metadata should keep OCI annotations and image labels aligned.

By contributing, you agree that your contribution is licensed under the terms
of this repository's [LICENSE](LICENSE).
