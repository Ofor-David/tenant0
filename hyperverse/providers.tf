# Runs as tofu-runner@t0x-mgmt-state.iam.gserviceaccount.com via impersonation
# rather than the operator's own gcloud ADC credentials, the SA holds the
# org-level projectCreator/billing.user roles, and impersonation means
# no SA key ever gets downloaded or stored.

provider "google" {
  region                      = var.region
  impersonate_service_account = "tofu-runner@t0x-mgmt-state.iam.gserviceaccount.com"
}

provider "google-beta" {
  region                      = var.region
  impersonate_service_account = "tofu-runner@t0x-mgmt-state.iam.gserviceaccount.com"
}
