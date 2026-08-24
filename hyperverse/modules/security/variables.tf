variable "folder_id" {
  description = "Org folder this project is created under"
  type        = string
}

variable "billing_account_id" {
  description = "GCP billing account ID with the project credit attached"
  type        = string
  sensitive   = true
}

variable "org_id" {
  description = "GCP organization ID, needed for the org-level audit log sink"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region for the KMS keyring and BigQuery dataset"
  type        = string
}
