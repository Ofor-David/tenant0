# Phase 0/1 foundational infra, provisioned once, changed rarely, plan-gated.
#
# folders.tf   org folder layout
# projects.tf  t0-security, t0-cicd projects + enabled APIs
# security.tf  KMS keyring, audit log sink, SCC
# cicd.tf      Artifact Registry
# phase1.tf    prj-host-network, Shared VPC, GKE Autopilot (Phase 1, not yet written)
