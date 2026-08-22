# Phase 1 network project: Shared VPC host that Crossplane's tenant projects
# attach to in Phase 2. No tenant projects attach yet, that wiring is
# Crossplane's job when it creates a tenant. See gke.tf for the cluster that
# runs inside this network.

resource "google_project" "host_network" {
  name            = "t0-host-network"
  project_id      = "t0-host-network"
  folder_id       = var.folder_id
  billing_account = var.billing_account_id
}

locals {
  host_network_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_service" "host_network_apis" {
  for_each = toset(local.host_network_apis)
  project  = google_project.host_network.project_id
  service  = each.value

  disable_dependent_services = false
}

resource "google_compute_shared_vpc_host_project" "host_network" {
  project    = google_project.host_network.project_id
  depends_on = [google_project_service.host_network_apis]
}

resource "google_compute_network" "hyperverse" {
  project                 = google_project.host_network.project_id
  name                    = "t0-hyperverse-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.host_network_apis]
}

# Secondary ranges are required for a VPC-native (alias IP) cluster, the
# recommended default for new GKE clusters.
resource "google_compute_subnetwork" "hyperverse_us_central1" {
  project       = google_project.host_network.project_id
  name          = "t0-hyperverse-us-central1"
  region        = var.region
  network       = google_compute_network.hyperverse.id
  ip_cidr_range = "10.10.0.0/20"

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.20.0.0/16"
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.30.0.0/20"
  }
}
