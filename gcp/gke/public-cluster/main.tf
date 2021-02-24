# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE PUBLIC CLUSTER IN GOOGLE CLOUD PLATFORM
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  version = "~> 3.43.0"
  project = var.project
  region  = var.region
}

provider "google-beta" {
  version = "~> 3.43.0"
  project = var.project
  region  = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A PUBLIC CLUSTER IN GOOGLE CLOUD PLATFORM
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  # https://github.com/gruntwork-io/terraform-google-gke/tree/master/modules/gke-cluster
  source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-cluster?ref=v0.7.0"

  name = var.cluster_name

  project  = var.project
  location = var.location

  # We're deploying the cluster in the 'public' subnetwork to allow outbound internet access
  # See the network access tier table for full details:
  # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
  network = module.vpc_network.network

  subnetwork                   = module.vpc_network.public_subnetwork
  cluster_secondary_range_name = module.vpc_network.public_subnetwork_secondary_range_name

  alternative_default_service_account = var.override_default_node_pool_service_account ? module.gke_service_account.email : null

  enable_vertical_pod_autoscaling = var.enable_vertical_pod_autoscaling
  enable_workload_identity        = var.enable_workload_identity

  resource_labels = merge({}, var.cluster_resource_labels)
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NODE POOL
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name     = "main-pool"
  project  = var.project
  location = var.location
  cluster  = module.gke_cluster.name

  initial_node_count = "1"

  autoscaling {
    min_node_count = "1"
    max_node_count = "5"
  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    image_type   = "COS"
    machine_type = "n1-standard-1"

    labels = {
      all-pools-example = "true"
    }

    # Add a public tag to the instances. See the network access tier table for full details:
    # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
    tags = [
      module.vpc_network.public,
    ]

    disk_size_gb = "30"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = module.gke_service_account.email

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A CUSTOM SERVICE ACCOUNT TO USE WITH THE GKE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "gke_service_account" {
  source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-service-account?ref=v0.7.0"

  name        = var.cluster_service_account_name
  project     = var.project
  description = var.cluster_service_account_description

  service_account_roles = concat(
    [
      "roles/storage.objectViewer",
    ],
    var.service_account_roles,
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SERVICE ACCOUNTS FOR WORKLOADS
# ---------------------------------------------------------------------------------------------------------------------

module "gke_workload_identity_external_dns" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version    = "13.1.0"
  name       = "external-dns"
  namespace  = "external-dns"
  project_id = var.project
  roles      = ["roles/dns.admin"]

  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}

module "gke_workload_identity_traefik" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version    = "13.1.0"
  name       = "traefik"
  namespace  = "traefik"
  project_id = var.project
  roles      = ["roles/dns.admin"]

  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NETWORK TO DEPLOY THE CLUSTER TO
# ---------------------------------------------------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "vpc_network" {
  source = "github.com/gruntwork-io/terraform-google-network.git//modules/vpc-network?ref=v0.6.0"

  name_prefix = "${var.cluster_name}-network-${random_string.suffix.result}"
  project     = var.project
  region      = var.region

  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block
}
