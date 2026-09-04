# t0-security project: KMS keyring (ring only; per-tenant keys are created by
# Crossplane in Phase 2, see universe/), Cloud Audit Log sink to BigQuery,
# Security Command Center, and the Artifact Registry for the TEI image
# (Phase 3) - folded in from a dropped standalone t0-cicd project, which held
# nothing but this one repo and wasn't worth its own project/billing line at
# this scale. The CI pipeline itself (GitHub Actions workflow running
# `tofu plan` + `conftest test` against policy/) lives in .github/workflows/,
# not here; Terraform only provisions the registry the pipeline pushes to.

resource "google_project" "security" {
  name            = "t0-security"
  project_id      = "t0-security"
  folder_id       = var.folder_id
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
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

resource "google_project_service" "security_apis" {
  for_each = toset(local.security_apis)
  project  = google_project.security.project_id
  service  = each.value

  disable_dependent_services = false
}

resource "google_kms_key_ring" "tenant0" {
  name     = "tenant0-keyring"
  location = var.region
  project  = google_project.security.project_id

  depends_on = [google_project_service.security_apis]
}

resource "google_bigquery_dataset" "audit_logs" {
  dataset_id  = "audit_logs"
  project     = google_project.security.project_id
  location    = var.region
  description = "Org-wide Cloud Audit Log sink destination"

  depends_on = [google_project_service.security_apis]
}

resource "google_logging_organization_sink" "audit_sink" {
  name             = "tenant0-audit-sink"
  org_id           = var.org_id
  destination      = "bigquery.googleapis.com/projects/${google_project.security.project_id}/datasets/${google_bigquery_dataset.audit_logs.dataset_id}"
  include_children = true

  # Admin Activity + Data Access audit logs org-wide, all admin actions
  # land in the audit sink (SOC 2 CC7.2 / ISO 27001 A.8.15).
  filter = "logName:\"cloudaudit.googleapis.com\""
}

# The sink writes as its own service identity, grant it BigQuery Data Editor
# on the destination dataset so log entries actually land.
resource "google_bigquery_dataset_iam_member" "audit_sink_writer" {
  dataset_id = google_bigquery_dataset.audit_logs.dataset_id
  project    = google_project.security.project_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_organization_sink.audit_sink.writer_identity
}

# NOTE: enabling Security Command Center (Standard tier) at the org level is
# not consistently supported via Terraform for org onboarding, this is a
# documented manual step (console or `gcloud scc` at org level), same
# category as the t0x-mgmt-state bootstrap exception.

resource "google_artifact_registry_repository" "tenant0" {
  project       = google_project.security.project_id
  location      = var.region
  repository_id = "tenant0"
  format        = "DOCKER"
  description   = "TEI embedding-service images"

  depends_on = [google_project_service.security_apis]
}
