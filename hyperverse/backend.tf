# Remote state lives in the bucket inside t0x-mgmt-state, a manually created,
# one-time bootstrap project that predates everything Tofu itself manages,
# solving the chicken-and-egg problem of needing a place to store state before
# the projects that hold state exist.
terraform {
  backend "gcs" {
    bucket                      = "t0-tofu-state"
    prefix                      = "state"
    impersonate_service_account = "tofu-runner@t0x-mgmt-state.iam.gserviceaccount.com"
  }
}
