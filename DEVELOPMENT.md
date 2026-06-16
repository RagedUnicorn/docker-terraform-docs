# Development Guide

This document provides information for developers working on the terraform-docs
Docker image.

## Development Environment

### Prerequisites

- Docker installed and running (with BuildKit / buildx)
- Docker Compose installed
- Git for version control
- Text editor or IDE

### Project Structure

```
docker-terraform-docs/
├── Dockerfile               # Multi-stage: verified download + minimal runtime
├── docker-compose.yml       # Basic usage configuration
├── docker-compose.dev.yml   # Development environment (shell)
├── docker-compose.test.yml  # Test orchestration
├── .env                     # Default environment variables
├── examples/                # Runnable example module
│   ├── docker-compose.yml   # Workflow example (writable mount)
│   ├── main.tf              # Sample module with inputs and an output
│   └── README.md
├── test/                    # Container Structure Tests
│   ├── terraform-docs_test.yml
│   ├── terraform-docs_command_test.yml
│   └── terraform-docs_metadata_test.yml
└── docs/                    # Documentation assets
```

## How the Image Is Built

The Dockerfile uses two stages:

1. **Download + verify stage** - installs `curl`, downloads the terraform-docs
   release tarball and its `terraform-docs-v<ver>.sha256sum` file, reduces the
   combined sums file to the line for our tarball, asserts it is non-empty, and
   runs `sha256sum -c` before extracting the single `terraform-docs` binary with
   busybox `tar`. **This verification is the whole point of building our own
   image and must never be skipped.**
2. **Runtime stage** - a clean Alpine image with a non-root `terraform-docs` user
   and the verified binary copied in from the build stage. No extra runtime
   packages are installed - terraform-docs needs no network, git or
   ca-certificates at runtime.

The terraform-docs version is pinned via `ARG TERRAFORM_DOCS_VERSION` and updated
by Renovate using the `# renovate:` comment above it. `TARGETARCH` is supplied
automatically by buildx (and by BuildKit for single-platform `docker build`),
which lines up with terraform-docs' tarball arch naming (`amd64`, `arm64`).

> **Note on verification.** terraform-docs publishes a SHA256 checksum file but
> **no signature** (no cosign or GPG). A verified checksum is the strongest
> guarantee available upstream; we always verify it rather than extracting the
> download blindly.

> **Note on asset naming.** terraform-docs release assets carry a `v` prefix and
> a hyphen arch separator (`terraform-docs-v0.24.0-linux-amd64.tar.gz`), and one
> combined `terraform-docs-v0.24.0.sha256sum` file covers every asset.

## Development Workflow

### 1. Local Development Mode

The `docker-compose.dev.yml` file provides an interactive shell built from the
local Dockerfile:

```bash
# Build the image locally
docker compose -f docker-compose.dev.yml build

# Drop into a shell to run terraform-docs manually
docker compose -f docker-compose.dev.yml run --rm terraform-docs-dev

# Inside the container
terraform-docs --version
terraform-docs markdown .
```

### 2. Building the Image

```bash
# Basic build (BuildKit supplies TARGETARCH automatically)
docker build -t ragedunicorn/terraform-docs:dev .

# Build with version metadata
docker build \
  --build-arg TERRAFORM_DOCS_VERSION=0.24.0 \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --build-arg VERSION=0.24.0-alpine3.22.1-1 \
  -t ragedunicorn/terraform-docs:0.24.0-alpine3.22.1-1 .

# Multi-platform build (requires buildx). Do NOT set TARGETARCH by hand.
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg TERRAFORM_DOCS_VERSION=0.24.0 \
  --build-arg VERSION=0.24.0-alpine3.22.1-1 \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  -t ragedunicorn/terraform-docs:0.24.0-alpine3.22.1-1 .
```

### 3. Testing Your Changes

After making changes, always build and test locally:

```bash
docker build -t ragedunicorn/terraform-docs:test .
```

#### Running Tests (Cross-Platform)

**Linux/macOS:**

```bash
TERRAFORM_DOCS_VERSION=test docker compose -f docker-compose.test.yml run test-all
```

**Windows (PowerShell):**

```powershell
$env:TERRAFORM_DOCS_VERSION="test"; docker compose -f docker-compose.test.yml run test-all
```

**Windows (Command Prompt):**

```cmd
set TERRAFORM_DOCS_VERSION=test && docker compose -f docker-compose.test.yml run test-all
```

**Important:** Never test against remote images - they may have different labels
or configurations due to CI/CD overrides.

See [TEST.md](TEST.md) for detailed testing information.

## Making Changes

### Version Updates

This project uses [Renovate](https://docs.renovatebot.com/) to manage updates:

- **terraform-docs**: tracked via the GitHub releases datasource; the `v` prefix
  is stripped via an `extractVersion` rule in `renovate.json`.
- **Alpine Linux**: tracked via the Docker datasource on the `FROM` lines.

When Renovate creates a PR:

1. Review the changes
2. Check that CI passes all tests
3. Test the build locally for major updates
4. Merge if everything looks good

Manual updates are rarely needed. If required, edit `ARG TERRAFORM_DOCS_VERSION`
in the Dockerfile (and the `FROM alpine:X.Y.Z` lines for Alpine), then rebuild and
test. Remember to keep the `org.opencontainers.image.base.name` label and the
metadata test in sync with the Alpine version.

## Code Style and Best Practices

### Dockerfile Best Practices

1. **Verify everything**: never skip the checksum verification
2. **Single purpose**: keep `terraform-docs` as the only entrypoint - no extra tools
3. **Layer optimization**: group related commands to minimize layers
4. **Security**: run as the non-root `terraform-docs` user
5. **Labels**: follow OCI naming conventions

### Documentation

1. **README.md**: keep focused on user-facing information
2. **Comments**: explain non-obvious build steps in the Dockerfile
3. **Examples**: provide working examples for new features
4. **Commit messages**: use conventional format (`feat:`, `fix:`, `docs:`, …)

## Debugging

### Common Issues

**Build failures (download/verify):**

```bash
# Verbose build output
docker build --progress=plain --no-cache -t ragedunicorn/terraform-docs:debug .
```

A failure at `sha256sum -c` means the download did not match the published
checksum - investigate before doing anything else; do not work around the
verification. If the `grep` for the tarball line yields an empty file, confirm
the checksum file's column separator (standard `sha256sum` output uses two
spaces).

**terraform-docs not working:**

```bash
docker run --rm --entrypoint sh ragedunicorn/terraform-docs:dev -c "which terraform-docs && terraform-docs --version"
```

**`--output-file` cannot write:**

`--output-file` needs a writable workspace. Mount `/workspace` writable (the
default) and match your host user so the written file stays owned by you.

## Contributing

### Before Submitting Changes

1. Run the full test suite
2. Update documentation if needed
3. Add tests for new behavior
4. Follow the existing style
5. Write clear commit messages

### Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit using conventional commits
4. Push to your fork
5. Open a Pull Request with a clear description

### Release Process

See [RELEASE.md](RELEASE.md) for information about creating releases.
