# terraform-docs Docker Examples

This directory contains a minimal Terraform module and a Docker Compose file that
demonstrate generating documentation with the image.

## Files

- `main.tf` - a small, provider-less module with a couple of inputs and an
  output (all with descriptions) so terraform-docs renders non-empty tables.
- `docker-compose.yml` - a workflow example with a writable workspace and host
  UID/GID matching for `--output-file`.

## Running the Example

### Using Docker directly

```bash
# From the repository root. Print markdown docs for the example module.
docker run --rm -v "$(pwd)/examples":/workspace ragedunicorn/terraform-docs:latest markdown .
```

### Using Docker Compose

```bash
docker compose -f examples/docker-compose.yml run --rm terraform-docs markdown .
```

### Expected Output

terraform-docs prints a markdown document with Inputs and Outputs tables:

```markdown
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Whether the greeting is enabled | `bool` | `true` | no |
| name | Name to greet | `string` | `"world"` | no |

## Outputs

| Name | Description |
|------|-------------|
| greeting | A friendly greeting built from var.name |
```

## Writing Docs Back Into a README

terraform-docs can inject the generated table into an existing file between
`<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` marker comments:

```bash
docker run --rm -v "$(pwd)/examples":/workspace \
  ragedunicorn/terraform-docs:latest markdown table --output-file README.md .
```

This needs a **writable** workspace (the default mount above is writable). Match
your host user so the written file stays owned by you.

## Notes for Real Modules

- **Writable workspace for `--output-file`.** Reading a module and printing to
  stdout works read-only, but injecting docs into a file needs write access.
- **File ownership.** The image runs as the non-root `terraform-docs` user.
  Match your host user with `--user "$(id -u):$(id -g)"` (docker run) or the
  `user:` field (compose) so any written files stay owned by you.
- **Output formats.** terraform-docs supports `markdown`, `markdown table`,
  `markdown document`, `json`, `yaml`, `tfvars hcl`, `tfvars json` and more -
  pass the format as the first argument.
- **Config file.** A `.terraform-docs.yml` in the module directory lets you pin
  formatting, sections and sort order; terraform-docs picks it up automatically.
