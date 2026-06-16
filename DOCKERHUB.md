# terraform-docs Alpine Docker Image

![Docker terraform-docs](https://raw.githubusercontent.com/RagedUnicorn/docker-terraform-docs/master/docs/docker_terraform_docs.png)

A lightweight [terraform-docs](https://github.com/terraform-docs/terraform-docs)
CLI built on Alpine Linux. The official terraform-docs release is
checksum-verified at build time, then shipped as a non-root, single-purpose image
with `terraform-docs` as its entrypoint.

## Quick Start

```bash
# Pull latest version
docker pull ragedunicorn/terraform-docs:latest

# Or pull a specific version
docker pull ragedunicorn/terraform-docs:0.24.0-alpine3.22.1-1

# Show the version
docker run --rm ragedunicorn/terraform-docs:latest --version

# Generate markdown docs for the module in the current directory
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform-docs:latest markdown .
```

## Features

- 🪶 **Small footprint**: minimal Alpine-based runtime image
- 🔐 **Verified download**: SHA256 checksum verified at build time (terraform-docs
  publishes no signature, so this is the strongest guarantee available)
- 🎯 **Single purpose**: `terraform-docs` is the entrypoint, nothing else bundled
- 🔒 **Runs as non-root**: executes as the unprivileged `terraform-docs` user
- 🏗️ **Multi-platform**: supports `linux/amd64` and `linux/arm64`
- 📦 **No runtime dependencies**: reads local files and writes docs, no network needed

## Usage Examples

### Generate a markdown table

```bash
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform-docs:latest markdown table .
```

### Inject docs into a README (writable mount)

```bash
docker run --rm -v "$(pwd)":/workspace \
  ragedunicorn/terraform-docs:latest markdown table --output-file README.md .
```

### Emit documentation as JSON

```bash
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform-docs:latest json .
```

### Match host user for bind-mount ownership

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace ragedunicorn/terraform-docs:latest markdown table --output-file README.md .
```

## Runtime Notes

- **Writable workspace for `--output-file`.** Printing to stdout works read-only,
  but injecting docs into a file needs write access. The default mount is writable.
- **Marker comments.** `--output-file` replaces the content between
  `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` in the target file.
- **Bind-mount ownership.** The container runs as the non-root `terraform-docs`
  user; match your host user with `--user "$(id -u):$(id -g)"` so files stay yours.
- **Configuration.** A `.terraform-docs.yml` in the module directory is picked up
  automatically to control format, sections and sort order.

## Tags

This image uses versioning that includes all component versions:

**Format:** `{terraform_docs_version}-alpine{alpine_version}-{build_number}`

### Version Examples

- `0.24.0-alpine3.22.1-1` - Initial release with terraform-docs 0.24.0 and Alpine 3.22.1
- `0.24.0-alpine3.22.1-2` - Rebuild of the same versions (base CVE patch, fixes)
- `0.24.0-alpine3.22.2-1` - Alpine Linux patch update
- `0.25.0-alpine3.22.1-1` - terraform-docs version update (build resets to 1)

## License

This image's build tooling is MIT-licensed. The bundled **terraform-docs binary**
is distributed by the terraform-docs project under the **MIT License** as well.
See the
[terraform-docs LICENSE](https://github.com/terraform-docs/terraform-docs/blob/master/LICENSE).

## Links

- **GitHub**: [https://github.com/RagedUnicorn/docker-terraform-docs](https://github.com/RagedUnicorn/docker-terraform-docs)
- **Issues**: [https://github.com/RagedUnicorn/docker-terraform-docs/issues](https://github.com/RagedUnicorn/docker-terraform-docs/issues)
- **Releases**: [https://github.com/RagedUnicorn/docker-terraform-docs/releases](https://github.com/RagedUnicorn/docker-terraform-docs/releases)
