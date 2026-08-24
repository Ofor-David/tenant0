# Deliberately non-compliant resource to prove the CI policy gate blocks a bad
# PR (exec plan §5.5). Delete this file once the gate proof is confirmed.
resource "google_storage_bucket" "noncompliant_test" {
  name     = "t0-noncompliant-gate-test"
  project  = "t0-cicd"
  location = "US"
}

resource "google_storage_bucket_iam_member" "noncompliant_test_public" {
  bucket = google_storage_bucket.noncompliant_test.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
