# GCP service account the Crossplane GCP provider family runs as (see
# universe-engine/providerconfig.yaml), bound to its fixed-name Kubernetes
# ServiceAccount via Workload Identity, so no downloaded key file is ever
# needed.

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
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${google_project.host_network.project_id}.svc.id.goog[crossplane-system/gcp-provider]"
}

# Permanent grants for running universe/composition.yaml's tenant stamp-out.
# Folder-scoped since Crossplane creates the tenant projects itself, so no
# narrower resource exists at grant time.
locals {
  crossplane_gcp_provider_folder_roles = [
    "roles/resourcemanager.projectCreator",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudsql.admin",
  ]
}

resource "google_folder_iam_member" "crossplane_gcp_provider" {
  for_each = toset(local.crossplane_gcp_provider_folder_roles)
  folder   = "folders/${var.folder_id}"
  role     = each.value
  member   = "serviceAccount:${google_service_account.crossplane_gcp_provider.email}"
}

# roles/billing.user for crossplane-gcp-provider is granted manually, not
# here: tofu-runner itself only holds billing.user on this billing account,
# not billing.admin, so it can't call setIamPolicy there. Same documented
# bootstrap-exception category as the SCC step in modules/security/main.tf.
# Granted via:
#   gcloud billing accounts add-iam-policy-binding <billing_account_id> \
#     --member="serviceAccount:crossplane-gcp-provider@t0-host-network.iam.gserviceaccount.com" \
#     --role="roles/billing.user"

resource "google_project_iam_member" "crossplane_gcp_provider_network_admin" {
  project = google_project.host_network.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.crossplane_gcp_provider.email}"
}

resource "google_kms_key_ring_iam_member" "crossplane_gcp_provider_kms" {
  key_ring_id = "projects/t0-security/locations/${var.region}/keyRings/tenant0-keyring"
  role        = "roles/cloudkms.admin"
  member      = "serviceAccount:${google_service_account.crossplane_gcp_provider.email}"
}
