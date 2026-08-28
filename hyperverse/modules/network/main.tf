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
    "cloudkms.googleapis.com",
    "networkconnectivity.googleapis.com",
    "serviceusage.googleapis.com",
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

# Dedicated subnet for Cloud SQL PSC consumer endpoints, separate from the GKE
# subnet (which carries secondary ranges). Matches the known-working PSC
# reference pattern; the SCP points at this subnet for endpoint IP allocation.
resource "google_compute_subnetwork" "psc_endpoints" {
  project       = google_project.host_network.project_id
  name          = "t0-hyperverse-psc-us-central1"
  region        = var.region
  network       = google_compute_network.hyperverse.id
  ip_cidr_range = "10.40.0.0/24"
}

# Authorizes Cloud SQL to auto-create PSC endpoints in this VPC. Without it,
# a tenant instance's pscAutoConnections status sits at NONE forever. Host-
# level singleton: one policy covers every current and future tenant.
resource "google_network_connectivity_service_connection_policy" "cloudsql" {
  project       = google_project.host_network.project_id
  name          = "t0-cloudsql-scp"
  location      = var.region
  service_class = "google-cloud-sql"
  network       = google_compute_network.hyperverse.id

  psc_config {
    subnetworks = [google_compute_subnetwork.psc_endpoints.id]
  }

  depends_on = [google_project_service.host_network_apis]
}

# The Network Connectivity service agent needs compute.networkUser to actually
# allocate the PSC endpoint in the subnet. The console grants this implicitly
# when an SCP is made there; creating the SCP via API/Terraform does not, so
# without this grant auto-connect silently stays at NONE.
resource "google_compute_subnetwork_iam_member" "networkconnectivity_agent" {
  project    = google_project.host_network.project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.psc_endpoints.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${google_project.host_network.number}@gcp-sa-networkconnectivity.iam.gserviceaccount.com"
}
