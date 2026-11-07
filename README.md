# infra-blueprints

Terraform modules and one example. The repo root has no `.tf` files. Nothing here is applied.

## What you can run

These commands were run on this tree with Terraform 1.9.8 and TFLint 0.65.0. Provider versions are what `terraform init` selected on 2026-11-07. `.gitignore` excludes `.terraform.lock.hcl`, so a later init can select a newer build inside the same `~>` range.

`terraform fmt -check -recursive` exits 3. The diff is indentation in `modules/cloudflare-worker/main.tf`, `modules/oracle-compute/main.tf`, and `modules/supabase-edge/main.tf`.

`terraform init -backend=false` at the repo root succeeds and reports an empty directory. `terraform validate` at the root then succeeds. That validate does not load `modules/` or `examples/`.

`tflint --init && tflint --recursive` exits 2:

- `examples/minimal-stack/main.tf` declares `provider "cloudflare"` and has no `required_providers` block
- `modules/supabase-edge/main.tf` uses `null_resource` and does not declare `hashicorp/null`

| Directory | `terraform init -backend=false` | `terraform validate` |
|---|---|---|
| `modules/cloudflare-worker` | ok, `cloudflare/cloudflare` 4.52.10 (`~> 4.40`) | fails |
| `modules/oracle-compute` | ok, `oracle/oci` 6.37.0 (`~> 6.21`) | fails |
| `modules/supabase-edge` | ok, `supabase/supabase` 1.11.1 (`~> 1.0`) and `hashicorp/null` 3.3.2 | ok |
| `examples/minimal-stack` | fails | fails |

## Files

```
.env.example
.gitignore
AGENTS.md
LICENSE
README.md
examples/minimal-stack/main.tf
examples/minimal-stack/worker.js
modules/cloudflare-worker/main.tf
modules/cloudflare-worker/variables.tf
modules/oracle-compute/main.tf
modules/oracle-compute/variables.tf
modules/supabase-edge/main.tf
modules/supabase-edge/variables.tf
.github/CODEOWNERS
.github/ISSUE_TEMPLATE/bug_report.yml
.github/ISSUE_TEMPLATE/feature_request.yml
.github/PULL_REQUEST_TEMPLATE.md
.github/workflows/ci.yml
```

Each `modules/*/variables.tf` is a single comment. Variables, the resource, and outputs are in that module's `main.tf`. Modules have no README and no `provider` block. `.github/CODEOWNERS` is `* @Zekiog`. `LICENSE` is MIT, copyright 2026 Zekk-s.

## modules/cloudflare-worker

Terraform `>= 1.9.0, < 2.0.0`. Provider `cloudflare/cloudflare` `~> 4.40`.

Variables in `main.tf`:

- `name` (string)
- `content` (string)
- `main_module` (string, default `"main"`)
- `bindings` (map of objects, default `{}`): `type`, `name`, optional `namespace_id`, optional `dataset_id`

`dataset_id` is never read. Dynamic blocks select `type` `kv`, `r2`, and `d1`.

Resource `cloudflare_worker_script.this`:

- arguments `name`, `content`, `main_module`
- `kv_namespace_binding` for `type == "kv"` (`name`, `namespace_id`)
- `r2_bucket_binding` for `type == "r2"` (`name`, `bucket_name` set from `namespace_id`)
- `d1_binding` for `type == "d1"` (`name`, `database_id` set from `namespace_id`)

Output `worker_id` is `cloudflare_worker_script.this.id`.

`terraform validate` against the installed 4.52.10 provider fails:

- `account_id` is required on `cloudflare_worker_script` and is not set
- `main_module` is not an argument of that resource (the schema attribute is `module`)
- block type `d1_binding` is not in the schema (the schema block is `d1_database_binding`)

`kv_namespace_binding` and `r2_bucket_binding` are in that schema. This module does not declare a KV namespace, an R2 bucket, or a D1 database.

## modules/oracle-compute

Terraform `>= 1.9.0, < 2.0.0`. Provider `oracle/oci` `~> 6.21`.

Variables in `main.tf`:

- `compartment_ocid`, `subnet_ocid`, `availability_domain`, `image_ocid` (strings, no default)
- `shape` (string, default `"VM.Standard.E4.Flex"`)
- `ocpus` (number, default `2`)
- `memory_in_gbs` (number, default `16`)
- `display_name` (string, default `"zekk-s-node"`)
- `ssh_public_key` (string, no default)

Resource `oci_core_instance.this` sets `shape`, a `shape_config` (`ocpus`, `memory_in_gbs`), `source_details` (`source_type = "image"`, `source_id = var.image_ocid`, `boot_volume_size_in_gbs = 100`), `create_vnic_details` (`subnet_id`, `assign_public_ip = true`, `display_name = "${var.display_name}-vnic"`), and `metadata.ssh_authorized_keys = var.ssh_public_key`.

Outputs: `instance_id` (`oci_core_instance.this.id`) and `public_ip` (`oci_core_instance.this.create_vnic_details[0].public_ip`).

`terraform validate` against the installed 6.37.0 provider fails on `public_ip`. `create_vnic_details` has `assign_public_ip` and no `public_ip` attribute. The instance schema has a top-level `public_ip` attribute; the output does not use it.

`examples/minimal-stack` does not call this module. No OCI provider block is in the repo.

## modules/supabase-edge

Terraform `>= 1.9.0, < 2.0.0`. Provider `supabase/supabase` `~> 1.0` is declared. The file has no `supabase_*` resource. The installed 1.11.1 provider includes `supabase_edge_function`; this module does not use it.

Variables in `main.tf`:

- `project_ref` (string)
- `edge_function_name` (string)
- `entrypoint_path` (string, default `"supabase/functions"`)
- `verify_jwt` (bool, default `true`)

Local `function_dir` is `"${var.entrypoint_path}/${var.edge_function_name}"`.

Resource `null_resource.edge_function_deploy`:

- triggers `function_name`, `verify_jwt`, and `source_hash` (`sha256` over `filesha256` of `fileset(local.function_dir, "**/*")`)
- `local-exec` runs `supabase functions deploy <edge_function_name> --project-ref <project_ref> --no-verify-jwt=`. The flag value is `"false"` when `verify_jwt` is true and `"true"` when `verify_jwt` is false.

Output `edge_function_name` is `var.edge_function_name`.

`hashicorp/null` is not listed in `required_providers`. Init still installs null 3.3.2. Validate succeeds.

This repo has no `supabase/functions/` directory. `terraform plan` with placeholder `project_ref` and `edge_function_name` (no apply) still plans that `null_resource`. `source_hash` is `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`, the SHA-256 of an empty string.

## examples/minimal-stack

Terraform `>= 1.9.0, < 2.0.0`. One empty `provider "cloudflare"` block. No `required_providers` in the example.

Module `api` sources `../../modules/cloudflare-worker`:

- `name` = `"zekk-s-api"`
- `content` = `file("${path.module}/worker.js")`
- `main_module` = `"main"`
- binding `kv_cache`: `type` `"kv"`, `name` `"KV_CACHE"`, `namespace_id` `"REPLACE_WITH_KV_NAMESPACE_ID"`

`worker.js` exports a `fetch` handler. `/healthz` returns JSON `{"ok":true}`. Every other path returns text `not found` with status 404.

`terraform init` in this directory fails. The empty provider block is looked up as `hashicorp/cloudflare`, which is not in the registry. The module requires `cloudflare/cloudflare`.

The example calls `modules/cloudflare-worker` only.

## CI

`.github/workflows/ci.yml` runs on pull requests and on pushes to `main`. Job `terraform` uses `ubuntu-latest` and a 10 minute timeout:

1. `actions/checkout@v4`
2. `hashicorp/setup-terraform@v3` with Terraform `1.9.8`
3. `terraform fmt -check -recursive`
4. `terraform init -backend=false`
5. `terraform validate`
6. `terraform-linters/setup-tflint@v4` with `tflint_version: latest`
7. `tflint --init && tflint --recursive` with `continue-on-error: true`

The workflow has no plan or apply step. On the current files, step 3 fails, so the job stops before init, validate, and tflint. Root validate would not check `modules/` or `examples/` anyway.

## Other files

`.gitignore` ignores Terraform state, `.terraform/`, `.terraform.lock.hcl`, plan files, `crash.log`, `*.tfvars` (keeps `*.tfvars.example`), and `.vscode/`, `.idea/`, `.DS_Store`.

`.env.example` sets `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and `SUPABASE_ACCESS_TOKEN` to `replace_me`. `OCI_CONFIG_FILE` and `OCI_CONFIG_PROFILE` are comments. No `.tf` file reads those names. In cloudflare 4.52.10, `account_id` is not a provider argument. It is required on `cloudflare_worker_script`, and `modules/cloudflare-worker` does not pass it.

`.github/ISSUE_TEMPLATE/bug_report.yml` asks for a module path, repro steps, and expected and actual behavior. `.github/ISSUE_TEMPLATE/feature_request.yml` asks for motivation, the proposed change, and alternatives. `.github/PULL_REQUEST_TEMPLATE.md` is a summary, a change-type checklist, and checkboxes for fmt, validate, tflint, and AGENTS.md.

There is no `CONTRIBUTING.md` and no `SECURITY.md`.
