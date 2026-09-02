# AGENTS.md — infra-blueprints

## Purpose

Reusable Terraform modules. Small, composable, CI-validated.

## Hard rules

- **Never** commit state files (`*.tfstate*`).
- **Never** bake credentials in code. Use env vars or OCI config.
- **Never** widen a module's input surface without a documented reason in the PR description.
- Pessimistic provider constraints only (`~>`). No floating `>=`.
- Every module must pass `terraform validate` and `tflint`.

## Workflow

1. Branch from `main`: `git switch -c feat/<module>`.
2. Add module under `modules/<name>/` with `main.tf`, `variables.tf`, `README.md`.
3. Wire it into `examples/` if it's the first module of its kind.
4. Run: `terraform fmt -recursive && terraform init -backend=false && terraform validate`.
5. Open PR using `.github/PULL_REQUEST_TEMPLATE.md`.

## Code style

- One resource per module by default. Split only when complexity demands it.
- All `variable` blocks have `type` + `description`.
- `output` blocks for every externally useful attribute.
- Use `locals` for derived values, not chained `var.x.y`.

## Testing floor

- CI runs `terraform fmt -check -recursive`, `terraform validate`, and `tflint --recursive`.
- No live plan/apply in CI.

## File ownership

`.github/CODEOWNERS` routes every path to `@Zekiog`.

## Things to avoid

- Cross-module `variable` references — pass via `examples/` instead.
- Provider configs inside modules — providers live at the root of each composition.
