# universe

Crossplane XRD + Composition + Claims for tenant stamp-out (Phase 2).

- `xrd.yaml`, the schema a tenant Claim must satisfy (OpenAPI validation, first-line admission control)
- `composition.yaml`, the recipe: project, tenant SA, KMS key, Cloud SQL + PSC, GKE namespace,
  NetworkPolicy, Workload Identity, per-tenant Redis, per-tenant API key
- `policy/`, ValidatingAdmissionPolicy / OPA Gatekeeper for semantic admission control (e.g. reject `roles/owner`)
- `claims/`, example Claims (`tenant-a.yaml`, `tenant-b.yaml`)
