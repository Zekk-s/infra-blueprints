# infra-blueprints

Reusable Terraform modules for the `@Zekk-s` deployment surface. Three modules today, designed to be composed:

| Module | Purpose |
|---|---|
| `modules/cloudflare-worker` | Worker scripts + KV/R2/D1 bindings |
| `modules/oracle-compute`   | OCI Flex-shape VM with public IP + SSH |
| `modules/supabase-edge`    | Edge Function deploy (CLI-driven, hash-checked) |

## Layout

```
modules/
  cloudflare-worker/
  oracle-compute/
  supabase-edge/
examples/
  minimal-stack/   # full-stack composition (Worker + Edge + OCI)
```

## Quick start

```bash
terraform fmt -recursive
terraform init
terraform validate
tflint --recursive
```

Each module is intentionally small — single resource graph, narrow input set. Compose them in `examples/`.

## Versions

- Terraform `>= 1.9.0`
- Providers pinned with pessimistic constraints (`~>`)

## CI

`.github/workflows/ci.yml` runs `terraform fmt -check`, `terraform validate`, and `tflint` on every PR.

## License

MIT — see `LICENSE`.
