# Phase 0/1 foundational infra, provisioned once, changed rarely, plan-gated.
#
# folders.tf          org folder layout
# main.tf (this file)  module composition root
# moved.tf             state-rename map from the pre-module flat layout
#
# modules/security/    t0-security project, KMS keyring, audit sink, SCC
# modules/cicd/        t0-cicd project, Artifact Registry
# modules/network/      t0-host-network, Shared VPC, GKE Standard + node pools (Phase 1)

module "security" {
  source = "./modules/security"

  folder_id          = google_folder.tenant0.folder_id
  billing_account_id = var.billing_account_id
  org_id             = var.org_id
  region             = var.region
}

module "cicd" {
  source = "./modules/cicd"

  folder_id          = google_folder.tenant0.folder_id
  billing_account_id = var.billing_account_id
  region             = var.region
}

module "network" {
  source = "./modules/network"

  folder_id                    = google_folder.tenant0.folder_id
  billing_account_id           = var.billing_account_id
  region                       = var.region
  zone                         = var.zone
  crossplane_node_machine_type = var.crossplane_node_machine_type
  crossplane_node_count        = var.crossplane_node_count
  workloads_node_machine_type  = var.workloads_node_machine_type
  workloads_min_node_count     = var.workloads_min_node_count
  workloads_max_node_count     = var.workloads_max_node_count
}
