# t0-cicd project: Artifact Registry for the TEI image (Phase 3).
# The CI pipeline itself (GitHub Actions workflow running `tofu plan` +
# `conftest test` against policy/) lives in .github/workflows/, not here.
# Terraform only provisions the registry the pipeline pushes to.

resource "google_project" "cicd" {
  name            = "t0-cicd"
  project_id      = "t0-cicd"
  folder_id       = var.folder_id
  billing_account = var.billing_account_id
}

locals {
  cicd_apis = [
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

resource "google_project_service" "cicd_apis" {
  for_each = toset(local.cicd_apis)
  project  = google_project.cicd.project_id
  service  = each.value

  disable_dependent_services = false
}

resource "google_artifact_registry_repository" "tenant0" {
  project       = google_project.cicd.project_id
  location      = var.region
  repository_id = "tenant0"
  format        = "DOCKER"
  description   = "TEI embedding-service images"

  depends_on = [google_project_service.cicd_apis]
}
