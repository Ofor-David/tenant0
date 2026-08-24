variable "folder_id" {
  description = "Org folder this project is created under"
  type        = string
}

variable "billing_account_id" {
  description = "GCP billing account ID with the project credit attached"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region for the subnet"
  type        = string
}

variable "zone" {
  description = "Single zone for the zonal GKE cluster (regional would replicate node pools per zone, multiplying cost for no benefit at this project's scale)"
  type        = string
}

variable "crossplane_node_machine_type" {
  description = "Machine type for the tainted node pool that runs Crossplane's controllers"
  type        = string
}

variable "crossplane_node_count" {
  description = "Fixed node count for the Crossplane pool, not autoscaled since Crossplane's control plane load doesn't scale with tenant count"
  type        = number
}

variable "workloads_node_machine_type" {
  description = "Machine type for the node pool that runs tenant serving workloads"
  type        = string
}

variable "workloads_min_node_count" {
  description = "Minimum nodes for the workloads pool, 0 lets it scale to no cost when idle"
  type        = number
}

variable "workloads_max_node_count" {
  description = "Maximum nodes for the workloads pool"
  type        = number
}
