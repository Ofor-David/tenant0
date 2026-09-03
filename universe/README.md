# universe

Crossplane XRDs and Compositions for tenant stamp-out (Phase 2). This directory holds only the
reusable schema and recipe, two sibling directories cover the rest:
- `universe-claims/`, the actual per-tenant requests
- `universe-engine/`, the Crossplane install itself (the control plane that reconciles this
  directory's recipes against `universe-claims/`'s requests) plus External Secrets Operator and
  a cluster-level admission policy restricting who can create/delete `Tenant` XRs or edit the
  Composition/XRD that governs every tenant

- `xrd.yaml`, the schema a `Tenant` XR instance must satisfy (OpenAPI validation, first-line admission control)
- `composition.yaml`, a thin orchestrator composing 5 nested sub-XRs, one per domain (split out
  once the recipe grew past ~1240 lines in one file):
  - `tenant-project/`, GCP project + identity foundation (project, API enablement, tenant SA + IAM
    grants, operator grants)
  - `tenant-database/`, Cloud SQL + CMEK (KMS key, DatabaseInstance with PSC, pgvector migration)
  - `tenant-network/`, GKE namespace, NetworkPolicy, ResourceQuota, Workload Identity plumbing
  - `tenant-workloads/`, per-tenant application workloads (Redis; future home for the serving path)
  - `tenant-secrets/`, per-tenant API key (real GCP Secret Manager value synced in via External
    Secrets Operator)

  Each sub-directory has its own `xrd.yaml`/`composition.yaml` pair, applied in dependency order
  by `apply.sh` (children before the parent).

## Why this is split across three directories

`universe/` holds the reusable schema and recipe (XRD + Composition), the same for every tenant.
`universe-claims/` holds the actual per-tenant requests (one YAML file per tenant), the
part that changes every time a tenant is onboarded or offboarded. `universe-engine/` holds the
Helm-based install of Crossplane itself, the runtime, not a recipe or a request. Splitting all three
keeps the reusable-template directory stable while the claims directory churns and the engine's
install manifests stay independent of both.
