terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40"
    }
  }
}

variable "name" {
  type        = string
  description = "Worker script name. Must be DNS-valid."
}

variable "content" {
  type        = string
  description = "Worker JavaScript / TypeScript bundle (post-build)."
}

variable "main_module" {
  type        = string
  default     = "main"
  description = "Entry module name."
}

variable "bindings" {
  type = map(object({
    type        = string
    name        = string
    namespace_id = optional(string)
    dataset_id  = optional(string)
  }))
  default     = {}
  description = "Worker bindings (KV, R2, D1, Durable Objects, etc)."
}

resource "cloudflare_worker_script" "this" {
  name    = var.name
  content = var.content
  main_module = var.main_module

  dynamic "kv_namespace_binding" {
    for_each = { for k, v in var.bindings : k => v if v.type == "kv" }
    content {
      name         = kv_namespace_binding.value.name
      namespace_id = kv_namespace_binding.value.namespace_id
    }
  }

  dynamic "r2_bucket_binding" {
    for_each = { for k, v in var.bindings : k => v if v.type == "r2" }
    content {
      name        = r2_bucket_binding.value.name
      bucket_name = r2_bucket_binding.value.namespace_id
    }
  }

  dynamic "d1_binding" {
    for_each = { for k, v in var.bindings : k => v if v.type == "d1" }
    content {
      name        = d1_binding.value.name
      database_id = d1_binding.value.namespace_id
    }
  }
}

output "worker_id" {
  value = cloudflare_worker_script.this.id
}
