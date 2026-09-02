terraform {
  required_version = ">= 1.9.0, < 2.0.0"
}

provider "cloudflare" {
  # CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID via env
}

# Deploy a single Worker that proxies to the Edge Function
module "api" {
  source      = "../../modules/cloudflare-worker"
  name        = "zekk-s-api"
  content     = file("${path.module}/worker.js")
  main_module = "main"

  bindings = {
    kv_cache = {
      type         = "kv"
      name         = "KV_CACHE"
      namespace_id = "REPLACE_WITH_KV_NAMESPACE_ID"
    }
  }
}
