############################################
# Download + verify stage
############################################
FROM alpine:3.24.1 AS build

# renovate: datasource=github-releases depName=terraform-docs/terraform-docs
ARG TERRAFORM_DOCS_VERSION=0.24.0
# Provided automatically by buildx (linux/amd64 -> amd64, linux/arm64 -> arm64)
ARG TARGETARCH

# Build stage labels
LABEL org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/RagedUnicorn/docker-terraform-docs" \
      org.opencontainers.image.licenses="MIT"

# Tools needed to download and verify the release:
#   curl - download the release assets
# (busybox tar, already in the base image, extracts the tar.gz)
RUN apk add --no-cache --update curl

WORKDIR /tmp/build

# Download the terraform-docs release, then verify it before use:
#   verify the tarball's checksum against the published SHA256SUM file
# Upstream publishes NO signature (no cosign/GPG), so a SHA256 checksum is the
# strongest verification available - we still never skip it, as it is the whole
# point of building our own image rather than blindly extracting a download.
#
# Note: terraform-docs assets carry a 'v' prefix and a hyphen arch separator
# (terraform-docs-v<ver>-linux-amd64.tar.gz), and a single combined sums file
# (terraform-docs-v<ver>.sha256sum) covers every asset in the release.
RUN set -eux; \
    base="https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}"; \
    file="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${TARGETARCH}.tar.gz"; \
    sums="terraform-docs-v${TERRAFORM_DOCS_VERSION}.sha256sum"; \
    curl -fsSLO "${base}/${file}"; \
    curl -fsSLO "${base}/${sums}"; \
    # Reduce the combined sums file to just our tarball's line and assert it is
    # non-empty, otherwise an empty checksum list would make `sha256sum -c`
    # pass silently.
    grep "  ${file}\$" "${sums}" > "${file}.sha256"; \
    [ -s "${file}.sha256" ]; \
    sha256sum -c "${file}.sha256"; \
    mkdir -p /out; \
    tar xzf "${file}" -C /out terraform-docs; \
    /out/terraform-docs --version

############################################
# Runtime stage
############################################
FROM alpine:3.24.1

ARG BUILD_DATE
ARG VERSION

# OCI-compliant labels
LABEL org.opencontainers.image.title="terraform-docs on Alpine Linux" \
      org.opencontainers.image.description="Lightweight terraform-docs Docker image built on Alpine Linux" \
      org.opencontainers.image.vendor="ragedunicorn" \
      org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/RagedUnicorn/docker-terraform-docs" \
      org.opencontainers.image.documentation="https://github.com/RagedUnicorn/docker-terraform-docs/blob/master/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="docker.io/library/alpine:3.24.1"

# No runtime dependencies: terraform-docs reads local .tf files and writes to
# stdout (or a file with --output-file). It needs no network, git, or
# ca-certificates at runtime.

# Non-root user. A real home is created so any per-user state stays writable.
RUN adduser -D -h /home/terraform-docs -s /sbin/nologin terraform-docs

COPY --from=build /out/terraform-docs /usr/local/bin/terraform-docs

# /workspace stays writable so `--output-file` can write back into the module.
WORKDIR /workspace
RUN chown -R terraform-docs:terraform-docs /workspace

USER terraform-docs

# terraform-docs is the entrypoint; pass any subcommand/flags as `docker run` args
ENTRYPOINT ["terraform-docs"]

# Default to showing help if no arguments are provided
CMD ["--help"]
