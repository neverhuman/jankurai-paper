# Testing and proof lanes

This repository has no executable product code; its "tests" are the deterministic
build of the paper plus the jankurai self-audit. A green build means the TeX
compiles end to end and the audit gate passes.

## Lanes

Every lane is exposed three ways so local runs and CI execute identical commands:
through the root [`Justfile`](../Justfile), through
[`scripts/ci-local.sh`](../scripts/ci-local.sh), and through the matching
`ops/ci/<lane>.sh` script.

| Lane | Command | Proves |
| --- | --- | --- |
| `required` | `bash ops/ci/required.sh` | the paper PDF compiles from `paper/jankurai.tex` |
| `fast` | `bash ops/ci/fast.sh` | the paper builds, then the jankurai self-audit passes |
| `audit` | `bash ops/ci/audit.sh` | writes `.jankurai/repo-score.{json,md}` and asserts they exist |

The narrowest proof loop for agent iteration is `just fast`.

## Determinism

The build is reproducible: `latexmk` is driven non-interactively
(`-interaction=nonstopmode -halt-on-error`) and all output is routed to the
`paper/` out-dir. The bibliography and generated tables are derived from
committed data sources under `paper/data/`, so the same inputs always produce the
same PDF.

## Routing

Each owned path is mapped to its proof command in
[`agent/test-map.json`](../agent/test-map.json). Changes under `paper/` route to
the `latexmk` build; changes under `agent/`, `docs/`, or release metadata route
to the jankurai audit lane.

## Observability

Each lane prints structured `[ci] <message>` progress lines via the shared
`log` helper in `ops/ci/lib.sh`, and the audit lane asserts every promised
artifact exists before the lane is allowed to pass. CI uploads the
`repo-score` artifacts so every run leaves an inspectable score trail.

## Repair receipts and telemetry

When a lane fails, keep the next agent on the shortest possible rerun path. Every
failure is surfaced as a **typed exception surface**, not free-form prose, with
these fields so the next rerun stays local:

- `purpose` — what the lane was proving (e.g. "the paper PDF compiles").
- `reason` — why it failed (the failing command and its exit code).
- `common fixes` — the usual remedies (missing TeX package, a `\input` typo, a
  stale `paper/jankurai.fdb_latexmk` cache to delete).
- `docs_url` — the local doc that explains the lane: this file,
  [`docs/release.md`](release.md), or [`docs/exceptions.md`](exceptions.md).
- `repair_hint` — the exact rerun command, e.g. `just fast` or
  `bash ops/ci/quality-gates.sh`.

The jankurai audit lane already emits this as structured JSON: the repair queue
under `.jankurai/repo-score.json` carries, per finding, the `rule_id`, `path`,
`message`, and the `Fix`/`Rerun` hint. That receipt convention — repair hint plus
rerun command plus docs URL, surfaced together — is the single source of repair
truth; prefer it over ad hoc log spam under `target/jankurai/`.

## Cost budget and stop conditions

The paper build and audit are cheap, bounded, single-shot CI jobs. Explicit
budgets, quotas, and stop conditions bound every lane:

- **Budget / quota**: each job declares a hard `timeout-minutes` in
  [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) (build 30, security
  15, audit 20, tool-adoption 20). A run that exceeds its quota is killed by the
  runner.
- **Stop condition**: every lane script runs under `set -euo pipefail` and
  `latexmk` uses `-halt-on-error`, so the build stops on the first error rather
  than burning minutes retrying.
- **Kill switch**: cancel an in-flight run via the `concurrency` group in
  `ci.yml` (`cancel-in-progress: true`); a new push cancels the superseded run.
  Locally, the pre-push gate (`ops/git-hooks/pre-push`) blocks before any CI
  spend.
- **No paid surface**: there is no network egress beyond pinned toolchain
  install and no paid API usage, so the per-run cost is bounded to the CI minutes
  for one `latexmk` build plus one audit.

## Build acceleration

The fast lane is incremental: `latexmk` reuses its `paper/jankurai.fdb_latexmk`
and `paper/jankurai.fls` dependency database to rebuild only changed sections,
and CI restores the TeX Live install and that latexmk build state from
`actions/cache` keyed on the TeX and bib sources (see the `Cache TeX Live` step
in [`ci.yml`](../.github/workflows/ci.yml)). The proof loop is targeted: a
change under `paper/` reruns only the paper build, not the whole gate.

## CI

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) runs the `build`
(fast) and `audit` jobs on every push and pull request. All third-party actions
are pinned to full commit SHAs.
