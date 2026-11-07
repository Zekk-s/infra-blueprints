terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}

variable "project_ref" {
  type        = string
  description = "Supabase project reference (e.g. abcdefghijkl)."
}

variable "edge_function_name" {
  type        = string
  description = "Function name. Used in the deploy command and in function_dir."
}

variable "entrypoint_path" {
  type        = string
  default     = "supabase/functions"
  description = "Path to the supabase/functions directory."
}

variable "verify_jwt" {
  type        = bool
  default     = true
  description = "Require a valid JWT to invoke the function."
}

# local-exec runs `supabase functions deploy`. No supabase_* resource is declared.

locals {
  function_dir = "${var.entrypoint_path}/${var.edge_function_name}"
}

resource "null_resource" "edge_function_deploy" {
  triggers = {
    function_name = var.edge_function_name
    verify_jwt    = var.verify_jwt
    # Re-deploy whenever any source file changes
    source_hash = sha256(join("", [
      for f in fileset(local.function_dir, "**/*") :
      filesha256("${local.function_dir}/${f}")
    ]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      supabase functions deploy ${var.edge_function_name} \
        --project-ref ${var.project_ref} \
        --no-verify-jwt=${
      var.verify_jwt ? "false" : "true"
    }
    EOT
  }
}

output "edge_function_name" {
  value = var.edge_function_name
}
