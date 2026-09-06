# Cloud NAT: internet egress for nodes now that gke.tf's private_cluster_config
# gives them no external IP. Needed for anything not on *.googleapis.com -
# ghcr.io (TEI's base image), Docker Hub, huggingface.co, and the apt
# mirrors pgvector-migration's package install step uses. Artifact Registry
# pulls are covered by private_ip_google_access instead.
resource "google_compute_router" "hyperverse" {
  project = google_project.host_network.project_id
  name    = "t0-hyperverse-router"
  region  = var.region
  network = google_compute_network.hyperverse.id
}

resource "google_compute_router_nat" "hyperverse" {
  project                            = google_project.host_network.project_id
  name                               = "t0-hyperverse-nat"
  router                             = google_compute_router.hyperverse.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# GKE's private-cluster automation only opens the master CIDR to nodes on
# 443/10250 by default. Crossplane's own webhook (crossplane-webhooks,
# confirmed live via `kubectl get validatingwebhookconfigurations`) listens
# on 9443, a known gap for private clusters running Crossplane - without
# this, the control plane can't reach the webhook and every Composition/XRD
# apply hangs waiting on it. No target_tags: applies network-wide, matching
# this network's single-cluster scope.
resource "google_compute_firewall" "master_to_crossplane_webhook" {
  project   = google_project.host_network.project_id
  name      = "t0-hyperverse-allow-master-crossplane-webhook"
  network   = google_compute_network.hyperverse.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["9443"]
  }

  source_ranges = ["172.16.0.0/28"] # gke.tf's master_ipv4_cidr_block
}
