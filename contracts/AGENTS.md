# contracts/ Agent Instructions

This directory holds the machine-readable data contracts for the paper.

## Owns

- `contracts/json-schema/*.schema.json` — JSON Schema documents that pin the
  shape of the committed paper data under `paper/data/`. These are the source of
  truth for the generated TeX tables under `paper/tex/generated/`.

## Forbidden

- Do not hand-edit the generated TeX tables in `paper/tex/generated/`; they are
  generated output (see `agent/generated-zones.toml`). Edit the data and the
  contract here, then regenerate.
- Do not let a schema drift from the data it describes; the audit lane flags a
  contract source that lacks a generated-zone entry.

## Proof lane

Generation and drift are gated by the jankurai audit lane: run `just audit`
(or `bash ops/ci/audit.sh`). Every contract source must have a matching
`[[zone]]` in `agent/generated-zones.toml` whose `command` regenerates the
output from this contract.
