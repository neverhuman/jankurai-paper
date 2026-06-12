# Contracts

This directory holds the machine-readable data contracts for the paper. The
paper's generated TeX tables under `paper/tex/generated/` are typed output
derived from these contracts; the contracts are the source of truth and the
generated tables are never hand-edited.

## Layout

- `json-schema/` — JSON Schema documents that pin the shape of the committed
  paper data under `paper/data/`.

## Drift

Contract drift is gated by the jankurai audit lane (`just audit`), which checks
that every contract source has a generated-zone entry in
[`agent/generated-zones.toml`](../agent/generated-zones.toml) and that the
generated TeX tables stay consistent with their data sources. Regenerate tables
from data via the documented commands in [`paper/README.md`](../paper/README.md);
never edit `paper/tex/generated/` by hand.
