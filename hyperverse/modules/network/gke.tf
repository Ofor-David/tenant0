# GKE Standard cluster + node pools that run inside the network defined in
# main.tf. Standard, not Autopilot: Crossplane's cluster-scoped controllers
# need privileged/hostPath-style access that Autopilot's Pod Security
# Standard blocks. One cluster, two node pools splits the blast radius
# instead of paying for a second cluster's management fee: a tiny tainted
# pool runs Crossplane, a separate autoscaling pool runs tenant serving
# workloads. The isolation boundary this project demonstrates is the GCP
# project (project-per-tenant), not the Kubernetes cluster, so Autopilot's
# per-pod sandboxing wasn't buying the thesis anything here.

# Zonal, not regional: a regional cluster replicates each node pool across
# every zone in the region, multiplying node cost for no benefit at this
# project's scale (n=1-2 tenants, demo).
resource "google_container_cluster" "hyperverse" {
  project  = google_project.host_network.project_id
  name     = "t0-hyperverse-cluster"
  location = var.zone

  network    = google_compute_network.hyperverse.id
  subnetwork = google_compute_subnetwork.hyperverse_us_central1.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  workload_identity_config {
    workload_pool = "${google_project.host_network.project_id}.svc.id.goog"
  }

  # Dataplane V2 (Cilium-backed), required for NetworkPolicy enforcement.
  # Immutable field: any change here forces full cluster replacement.
  datapath_provider = "ADVANCED_DATAPATH"

  # Node pools are managed as separate resources below, GKE requires the
  # cluster to be created with a default pool that's then immediately
  # removed.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Portfolio project, not a persistent production cluster, plan includes a
  # full hyperverse teardown/rebuild cycle.
  deletion_protection = false
}

# Small, fixed-size, tainted so only Crossplane's controllers schedule here.
resource "google_container_node_pool" "crossplane" {
  project  = google_project.host_network.project_id
  name     = "crossplane"
  cluster  = google_container_cluster.hyperverse.name
  location = var.zone

  node_count = var.crossplane_node_count

  node_config {
    machine_type = var.crossplane_node_machine_type
    disk_size_gb = 30

    taint {
      key    = "dedicated"
      value  = "crossplane"
      effect = "NO_SCHEDULE"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# Autoscales to zero when no tenant workload is running, this is where
# actual tenant serving pods (and, later, Crossplane-provisioned per-tenant
# resources that need in-cluster compute) land.
resource "google_container_node_pool" "workloads" {
  project  = google_project.host_network.project_id
  name     = "workloads"
  cluster  = google_container_cluster.hyperverse.name
  location = var.zone

  autoscaling {
    min_node_count = var.workloads_min_node_count
    max_node_count = var.workloads_max_node_count
  }

  node_config {
    machine_type = var.workloads_node_machine_type
    # GKE's default (100GB) sized this pool to consume 200GB of the
    # region's 250GB SSD_TOTAL_GB quota across just 2 nodes, blocking the
    # autoscaler's 3rd-node scale-up with "GCE quota exceeded" - confirmed
    # via `gcloud compute operations list ... targetLink~workloads`
    # surfacing the real SSD_TOTAL_GB error (Kubernetes' own
    # "Insufficient cpu" scheduling message was a red herring, the pool
    # never actually ran out of CPU capacity). 30GB matches the crossplane
    # pool's own explicit sizing and is plenty for these workloads (Redis,
    # short-lived migration Jobs).
    disk_size_gb = 30

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
