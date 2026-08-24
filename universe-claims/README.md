# universe-claims

Actual per-tenant Crossplane Claims (`tenant-a.yaml`, `tenant-b.yaml`, ...), each requesting an
instance of the XRD defined in `universe/`. This directory is expected to churn as tenants are
onboarded and offboarded; the schema and recipe that govern what a Claim can request live in
`universe/`, not here.
