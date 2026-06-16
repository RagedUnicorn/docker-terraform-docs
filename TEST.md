# Testing Guide

This document describes how to test the terraform-docs Docker image using
Container Structure Tests.

## Quick Start

```bash
# Build the image locally first
docker build -t ragedunicorn/terraform-docs:test .

# Run all tests
TERRAFORM_DOCS_VERSION=test docker compose -f docker-compose.test.yml run test-all

# Run individual test suites
TERRAFORM_DOCS_VERSION=test docker compose -f docker-compose.test.yml up container-test          # File structure
TERRAFORM_DOCS_VERSION=test docker compose -f docker-compose.test.yml up container-test-command  # Command execution
TERRAFORM_DOCS_VERSION=test docker compose -f docker-compose.test.yml up container-test-metadata # Metadata
```

## Test Structure

The test suite consists of three files:

### 1. File Structure Tests (`test/terraform-docs_test.yml`)

Validates:

- The `terraform-docs` binary exists at `/usr/local/bin/terraform-docs` with the
  expected permissions
- The `/workspace` working directory exists
- `terraform-docs --version` runs and the working directory is `/workspace`

### 2. Command Execution Tests (`test/terraform-docs_command_test.yml`)

Validates:

- `terraform-docs --version` and `terraform-docs --help` output
- The working directory is `/workspace`
- The container runs as the non-root `terraform-docs` user
- Generating markdown for a sample module renders Inputs/Outputs tables (reads
  only local files, fully offline)

### 3. Metadata Tests (`test/terraform-docs_metadata_test.yml`)

Validates:

- OCI-compliant labels are present and correct
- The entrypoint is `terraform-docs` and the default command is `--help`
- The working directory is `/workspace`
- The image runs as the `terraform-docs` user

## Running Tests

### Prerequisites

1. Docker must be installed and running
2. Build the terraform-docs image locally before testing

### Important: Always Test Local Builds

**⚠️ Always build and test locally to ensure consistency:**

```bash
docker build -t ragedunicorn/terraform-docs:test .
```

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

**Why local testing is important:**
- Remote images (Docker Hub, GHCR) may have different labels due to CI/CD overrides
- Ensures you are testing exactly what you built
- Avoids false positives/negatives from version mismatches

**Never pull a remote image for testing** - build locally and test the `:test` tag.

### Running Specific Test Categories

**Linux/macOS:**

```bash
# File structure tests
TERRAFORM_DOCS_VERSION=test docker compose -f docker-compose.test.yml up container-test

# Command execution tests
TERRAFORM_DOCS_VERSION=test docker compose -f docker-compose.test.yml up container-test-command

# Metadata tests
TERRAFORM_DOCS_VERSION=test docker compose -f docker-compose.test.yml up container-test-metadata
```

**Windows (PowerShell):**

```powershell
$env:TERRAFORM_DOCS_VERSION="test"; docker compose -f docker-compose.test.yml up container-test
$env:TERRAFORM_DOCS_VERSION="test"; docker compose -f docker-compose.test.yml up container-test-command
$env:TERRAFORM_DOCS_VERSION="test"; docker compose -f docker-compose.test.yml up container-test-metadata
```

## Troubleshooting Test Failures

### Version-specific output

`terraform-docs --version` output changes with every release, so the command
tests match a stable prefix (`terraform-docs version`) rather than an exact
version. If you add stricter version assertions, remember to update them on every
Renovate bump.

### Generated-docs assertions

The command test asserts the generated markdown contains `## Inputs`, `## Outputs`
and a table header. terraform-docs' default markdown output is stable, but if a
future release changes the section headings, update the test's `expectedOutput`
accordingly.

### Metadata Test Failures

**Common causes:**

1. **Testing remote images instead of local builds** - remote labels are
   overridden by CI/CD. Always test your local `:test` build.
2. **Label value mismatches** - the `org.opencontainers.image.version` and
   `created` labels are dynamic and set at build time.
3. **Alpine version drift** - if you bump Alpine, update both the
   `org.opencontainers.image.base.name` label in the Dockerfile and the
   matching value in `test/terraform-docs_metadata_test.yml`.

### Permission Errors

If you encounter Docker socket permission errors:

```bash
sudo docker compose -f docker-compose.test.yml run test-all
```

Or ensure your user is in the `docker` group:

```bash
sudo usermod -aG docker "$USER"
# Log out and back in for changes to take effect
```

## CI/CD Integration

These tests run automatically in GitHub Actions:

- **On every push** to `master`
- **On every pull request** to `master`
- **Before releases** (the release workflow runs the full suite first and blocks
  the build/push if it fails)

The test workflow (`.github/workflows/test.yml`):
1. Builds the Docker image
2. Runs all Container Structure Tests
3. Runs a basic functionality smoke test (`--version`, then generating docs for a
   sample module) to catch a broken binary that `--version` alone would not surface
4. Blocks releases if anything fails

The `test-all` service returns:
- Exit code 0: all tests passed
- Exit code 1: one or more tests failed

## Test Maintenance

When updating the image:

1. **terraform-docs version updates**: usually no test changes needed (version-prefix matching)
2. **Alpine version updates**: update the `base.name` label and metadata test value
3. **New functionality**: add corresponding tests
4. **Label changes**: update the metadata test to match

Always run the full test suite before creating a release.
