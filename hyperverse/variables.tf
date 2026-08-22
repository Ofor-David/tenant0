variable "billing_account_id" {
  description = "GCP billing account ID with the project credit attached"
  type        = string
}

variable "org_id" {
  description = "GCP organization ID (folders and project-per-tenant require an org node)"
  type        = string
}

variable "region" {
  description = "Single pinned region for all resources"
  type        = string
  default     = "us-central1"
}
