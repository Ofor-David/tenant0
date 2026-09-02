# universe-claims

Actual per-tenant `Tenant` XR instances (one YAML file per tenant), each a direct
instance of the XRD defined in `universe/` — Crossplane v2 has no separate Claim kind, operators
apply the XR directly. This directory is expected to churn as tenants are onboarded and
offboarded; the schema and recipe that govern what a `Tenant` can request live in `universe/`,
not here.
