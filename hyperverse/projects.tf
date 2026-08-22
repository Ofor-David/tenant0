# Non-tenant spine projects.
# The Phase 1 network project (Shared VPC + GKE Autopilot) is not written yet
#, it'll follow the same t0-* naming convention as these two when it lands.

resource "google_project" "security" {
  name            = "t0-security"
  project_id      = "t0-security"
  folder_id       = google_folder.tenant0.folder_id
  billing_account = var.billing_account_id
}

resource "google_project" "cicd" {
  name            = "t0-cicd"
  project_id      = "t0-cicd"
  folder_id       = google_folder.tenant0.folder_id
  billing_account = var.billing_account_id
}

locals {
  security_apis = [
    "cloudkms.googleapis.com",
    "logging.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "securitycenter.googleapis.com",
  ]
  cicd_apis = [
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

resource "google_project_service" "security_apis" {
  for_each = toset(local.security_apis)
  project  = google_project.security.project_id
  service  = each.value

  disable_dependent_services = false
}

resource "google_project_service" "cicd_apis" {
  for_each = toset(local.cicd_apis)
  project  = google_project.cicd.project_id
  service  = each.value

  disable_dependent_services = false
}
