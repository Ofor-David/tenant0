# universe

Crossplane XRDs and Compositions for tenant stamp-out (Phase 2). This directory holds only the
reusable schema and recipe, two sibling directories cover the rest:
- `universe-claims/`, the actual per-tenant requests
- `universe-engine/`, the Crossplane install itself, the control plane that reconciles this
  directory's recipes against `universe-claims/`'s requests

- `xrd.yaml`, the schema a `Tenant` XR instance must satisfy (OpenAPI validation, first-line admission control)
- `composition.yaml`, the recipe: project, tenant SA, KMS key, Cloud SQL + PSC, GKE namespace,
  NetworkPolicy, Workload Identity, per-tenant Redis, per-tenant API key

## Why this is split across three directories

`universe/` holds the reusable schema and recipe (XRD + Composition), the same for every tenant.
`universe-claims/` holds the actual per-tenant requests (`tenant-b.yaml`, ...), the
part that changes every time a tenant is onboarded or offboarded. `universe-engine/` holds the
Helm-based install of Crossplane itself, the runtime, not a recipe or a request. Splitting all three
keeps the reusable-template directory stable while the claims directory churns and the engine's
install manifests stay independent of both.
