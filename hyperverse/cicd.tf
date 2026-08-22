# t0-cicd: Artifact Registry for the TEI image (Phase 3).
# The CI pipeline itself (GitHub Actions workflow running `tofu plan` +
# `conftest test` against policy/) lives in .github/workflows/, not here.
# Terraform only provisions the registry the pipeline pushes to.

resource "google_artifact_registry_repository" "tenant0" {
  project       = google_project.cicd.project_id
  location      = var.region
  repository_id = "tenant0"
  format        = "DOCKER"
  description   = "TEI embedding-service images"

  depends_on = [google_project_service.cicd_apis]
}
