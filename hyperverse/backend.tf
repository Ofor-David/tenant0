# Remote state lives in the bucket inside t0-mgmt-state, a manually created,
# one-time bootstrap project (see docs/PHASE0_SETUP.md §2) that predates
# everything Tofu itself manages, solving the chicken-and-egg problem of
# needing a place to store state before the projects that hold state exist.
terraform {
  backend "gcs" {
    bucket = "t0-tofu-state"
    prefix = "state"
  }
}
