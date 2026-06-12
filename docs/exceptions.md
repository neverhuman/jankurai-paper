# Agent exceptions and overrides

This document defines the agent-friendly exception pattern for jankurai-paper:
how an agent or maintainer requests, records, and bounds an override of a
standard rule. Exceptions are the only sanctioned way to deviate from the audit
baseline.

## Principle

The default answer is "follow the standard." An exception is a dated, owned,
expiring waiver for a specific rule on a specific path. Exceptions are data, not
prose: they live next to the code they govern and are reviewed on every audit.

## How to request an exception

1. Identify the exact `rule_id` and `path` the exception applies to (from the
   audit JSON `findings[]`).
2. Add an entry to the relevant `agent/*.toml` manifest, or — for transient and
   teaching-corpus paths that must never be scanned — to the `[scan]` section of
   [`agent/audit-policy.toml`](../agent/audit-policy.toml).
3. Every exception entry MUST carry:
   - `owner` — the team or person accountable.
   - `classification` — e.g. `brownfield`, `temporary`, `vendor`, `corpus`.
   - `expires` — an ISO date after which the exception is invalid and the audit
     fails again.
   - `migration_path` — the concrete plan to remove the exception.

## Example

The generated TeX tables carry a documented exception in
[`agent/boundaries.toml`](../agent/boundaries.toml) using the standard
`[[streaming_exception]]` schema (`runtime`, `classification`, `reason`,
`owner`, `expires`, `migration_path`):

```toml
[[streaming_exception]]
runtime = "latex-generated-tables"
classification = "vendor"
reason = "Generated TeX tables are build output, not hand-authored source."
owner = "paper"
expires = "2026-12-31"
migration_path = "Regenerate via the documented jankurai paper commands in paper/README.md; never hand-edit."
```

The `tips/` teaching corpus is excluded from product scans via the scan policy:

```toml
[scan]
excluded_paths = ["tips", ".fusion", ".jankurai", "target"]
```

`tips/` is deliberate teaching material distilled from the paper, not product
source, so it is classified `corpus` and excluded permanently rather than fixed.

## Override review

- Every exception is re-evaluated on each `just audit` run.
- An expired exception is treated as a hard finding, not a pass.
- Removing an exception requires deleting its entry and proving the underlying
  rule now passes on its own.

## What is never excepted

Secret leakage, destructive migrations without rollback, and hand-edits to
generated zones are never granted exceptions. Fix the underlying cause instead.
