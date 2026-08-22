variable "folder_id" {
  description = "Org folder this project is created under"
  type        = string
}

variable "billing_account_id" {
  description = "GCP billing account ID with the project credit attached"
  type        = string
}

variable "region" {
  description = "Region for the Artifact Registry repository"
  type        = string
}
