# GCP service account the Crossplane GCP provider family runs as (see
# universe-engine/providerconfig.yaml), bound to its fixed-name Kubernetes
# ServiceAccount via Workload Identity, so no downloaded key file is ever
# needed. This SA's own permissions (project creation, Cloud SQL, KMS, etc.
# for tenant stamp-out) are deliberately not granted yet, the exact set
# depends on what universe/composition.yaml actually provisions, still
# unwritten as of this file.

resource "google_service_account" "crossplane_gcp_provider" {
  project      = google_project.host_network.project_id
  account_id   = "crossplane-gcp-provider"
  display_name = "Crossplane GCP provider (Workload Identity)"
}

# Lets the Kubernetes ServiceAccount crossplane-system/gcp-provider (the
# fixed name set in universe-engine/runtimeconfig.yaml's
# serviceAccountTemplate) impersonate this GCP service account.
resource "google_service_account_iam_member" "crossplane_gcp_provider_wi" {
  service_account_id = google_service_account.crossplane_gcp_provider.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:${google_project.host_network.project_id}.svc.id.goog[crossplane-system/gcp-provider]"
}
