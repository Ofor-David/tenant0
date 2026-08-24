# universe

Crossplane XRDs and Compositions for tenant stamp-out (Phase 2). Actual tenant Claims live in the
sibling `universe-claims/` directory, not here, see below.

- `xrd.yaml`, the schema a tenant Claim must satisfy (OpenAPI validation, first-line admission control)
- `composition.yaml`, the recipe: project, tenant SA, KMS key, Cloud SQL + PSC, GKE namespace,
  NetworkPolicy, Workload Identity, per-tenant Redis, per-tenant API key
- `policy/`, ValidatingAdmissionPolicy / OPA Gatekeeper for semantic admission control (e.g. reject `roles/owner`)

## Why Claims live in a separate directory

`universe/` holds the reusable schema and recipe (XRD + Composition), the same for every tenant.
`universe-claims/` holds the actual per-tenant requests (`tenant-a.yaml`, `tenant-b.yaml`, ...), the
part that changes every time a tenant is onboarded or offboarded. Splitting them keeps the
reusable-template directory stable while the claims directory churns, and makes it obvious at a
glance which files define the tenant contract versus which files consume it.
