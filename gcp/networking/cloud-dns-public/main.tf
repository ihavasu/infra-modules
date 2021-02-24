# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A PUBLIC MANAGED ZONE IN CLOUD DNS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A MANAGED ZONE
# ---------------------------------------------------------------------------------------------------------------------

module "cloud_dns_public" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "3.1.0"

  project_id = var.project

  type       = "public"
  domain     = var.domain
  name       = var.name
  recordsets = var.recordsets
}
