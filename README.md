# Tenant0

A GRC-aware, low-latency multi-tenant AI serving platform on GCP, built to the minimum bar that
survives a real enterprise security review, on a near-free-tier budget.

The core thesis: tenant isolation at the GCP **project** boundary, provisioned and enforced entirely
through code (OpenTofu + policy-as-code + Crossplane), not console clicks.

## Repo layout

| Path | What |
|---|---|
| `hyperverse/` | OpenTofu for the non-tenant infra: `security`, `cicd`, `network` projects, each its own module |
| `universe/` | Crossplane XRDs and Compositions for tenant stamp-out |
| `universe-claims/` | Per-tenant `Tenant` XR instances of the `universe/` XRD (Crossplane v2 has no separate Claim kind) |
| `universe-engine/` | Helmfile install of Crossplane itself, the control plane that reconciles `universe/` against `universe-claims/` |
| `policy/` | OPA/Conftest policies enforced in CI against `hyperverse/` |
| `.github/workflows/` | Merge-blocking `tofu plan` + policy gate on PRs touching `hyperverse/` or `policy/` |

## Quick start

```bash
cd hyperverse
tofu init
tofu plan
```
