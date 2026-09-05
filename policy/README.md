# policy

OPA / Conftest policies enforced in CI against `hyperverse/`.

Minimum set for Phase 0:
- no public storage buckets
- CMEK required on data stores
- no `roles/owner` in IAM bindings

Each policy maps to a control in the compliance matrix (see `docs/`).