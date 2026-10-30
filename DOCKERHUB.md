# terraform-docs Alpine Docker Image

![Docker terraform-docs](https://raw.githubusercontent.com/RagedUnicorn/docker-terraform-docs/master/docs/docker_terraform_docs_banner.png)

A lightweight [terraform-docs](https://github.com/terraform-docs/terraform-docs)
CLI built on Alpine Linux. The official terraform-docs release is
checksum-verified at build time, then shipped as a non-root, single-purpose image
with `terraform-docs` as its entrypoint.

## Quick Start

```bash
# Pull latest version
docker pull ragedunicorn/terraform-docs:latest

# Or pull a specific version (see the Tags tab for the available versions)
docker pull ragedunicorn/terraform-docs:<terraform-docs-version>-alpine<alpine-version>-<build>

# Show the version
docker run --rm ragedunicorn/terraform-docs:latest --version

# Generate markdown docs for the module in the current directory
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform-docs:latest markdown .
```

On Windows, use the PowerShell form - `${PWD}` **with braces** and the colon
inside the quotes (without braces PowerShell parses `$PWD:` as a
scope-qualified variable, as in `$env:PATH`, and rejects the argument):

```powershell
# Generate markdown docs for the module in the current directory
docker run --rm -v "${PWD}:/workspace" ragedunicorn/terraform-docs:latest markdown .
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

PowerShell:

```powershell
docker run --rm -v "${PWD}:/workspace" ragedunicorn/terraform-docs:latest markdown table .
```

### Inject docs into a README (writable mount)

```bash
docker run --rm -v "$(pwd)":/workspace \
  ragedunicorn/terraform-docs:latest markdown table --output-file README.md .
```

PowerShell:

```powershell
docker run --rm -v "${PWD}:/workspace" `
  ragedunicorn/terraform-docs:latest markdown table --output-file README.md .
```

### Emit documentation as JSON

```bash
docker run --rm -v "$(pwd)":/workspace ragedunicorn/terraform-docs:latest json .
```

PowerShell:

```powershell
docker run --rm -v "${PWD}:/workspace" ragedunicorn/terraform-docs:latest json .
```

### Match host user for bind-mount ownership

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace ragedunicorn/terraform-docs:latest markdown table --output-file README.md .
```

On Windows hosts this is not needed: Docker Desktop bind mounts do not carry
Unix file ownership, so `--user` matching has no effect (and `id` does not
exist in PowerShell).

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

`X.Y.Z` is the terraform-docs version, `A.B.C` the Alpine version:

- `X.Y.Z-alpineA.B.C-1` - terraform-docs X.Y.Z on Alpine A.B.C, build 1
- `X.Y.Z-alpineA.B.C-2` - Rebuild of the same versions (base CVE patch, fixes)
- `X.Y.Z-alpineA.B.D-1` - Alpine Linux patch update
- `X.Y+1.0-alpineA.B.C-1` - terraform-docs version update (build resets to 1)
- `X.Y.Z` - Most recent build of terraform-docs X.Y.Z
- `latest` - Most recent stable release

The available versions are listed in the [Tags tab](https://hub.docker.com/r/ragedunicorn/terraform-docs/tags).

## License

This image's build tooling is MIT-licensed. The bundled **terraform-docs binary**
is distributed by the terraform-docs project under the **MIT License** as well.
See the
[terraform-docs LICENSE](https://github.com/terraform-docs/terraform-docs/blob/master/LICENSE).

## Links

- **GitHub**: [https://github.com/RagedUnicorn/docker-terraform-docs](https://github.com/RagedUnicorn/docker-terraform-docs)
- **Issues**: [https://github.com/RagedUnicorn/docker-terraform-docs/issues](https://github.com/RagedUnicorn/docker-terraform-docs/issues)
- **Releases**: [https://github.com/RagedUnicorn/docker-terraform-docs/releases](https://github.com/RagedUnicorn/docker-terraform-docs/releases)
