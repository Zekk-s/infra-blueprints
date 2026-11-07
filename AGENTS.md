# AGENTS.md

## Repository

Three Terraform modules under `modules/` and one example under `examples/minimal-stack/`. Each module's variables, resource, and outputs are in `main.tf`. Each `variables.tf` is a comment. There is no root module and no module README.

`examples/minimal-stack` calls `modules/cloudflare-worker` only. `worker.js` answers `/healthz` with `{"ok":true}` and returns 404 for every other path. The example does not call `modules/oracle-compute` or `modules/supabase-edge`.

`terraform validate` fails in `modules/cloudflare-worker` and `modules/oracle-compute`. The errors are listed in `README.md`. Leave the resources as they are unless the change is an intentional fix. Do not add resources so an old doc sentence becomes true. Docs should describe the files in the tree.

## Rules

- Do not commit `*.tfstate*`, `.terraform/`, or credentials. `.gitignore` excludes state, `.terraform.lock.hcl`, and `*.tfvars`. Leave `.env.example` values as `replace_me`.
- Provider version constraints in the modules use `~>`.
- `.github/CODEOWNERS` is `* @Zekiog`.
- README text, comments, commit messages, and pull request text stay in English and match this tree.

## CI

`.github/workflows/ci.yml` runs on pull requests and on pushes to `main`. It installs Terraform 1.9.8 and, from the repo root, runs `terraform fmt -check -recursive`, `terraform init -backend=false`, and `terraform validate`. It then runs `tflint --init && tflint --recursive` with `continue-on-error: true`. The root has no `.tf` files, so that validate does not load `modules/` or `examples/`. The workflow does not plan or apply. `terraform fmt -check -recursive` currently fails on indentation in the three module `main.tf` files.
