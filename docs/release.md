# Release process

This document is the release control surface for jankurai-paper. It covers the
version source, the changelog, the release automation, integrity and SBOM
evidence, and rollback. Launch gates require every section below to be backed by
a real artifact or command.

## Version source

The single source of truth for the version is the [`VERSION`](../VERSION) file at
the repository root. The version recorded in
[`agent/standard-version.toml`](../agent/standard-version.toml) and any release
tag MUST match `VERSION`. Tags follow the family pattern
`jankurai-paper-v<MAJOR.MINOR.PATCH>-split.<N>` as described in
[`SPLIT.md`](../SPLIT.md) and [`.jeryu/repo.toml`](../.jeryu/repo.toml).

## Changelog

Every release records its user-visible changes in
[`CHANGELOG.md`](../CHANGELOG.md) under a heading that matches the new `VERSION`.
The `Unreleased` section is promoted to a dated version heading at tag time.

## Release automation

Releases are cut by CI, not by hand:

1. Bump [`VERSION`](../VERSION) and promote the `Unreleased` section of
   [`CHANGELOG.md`](../CHANGELOG.md).
2. Run the full local gate: `just check` (build the paper PDF, then run the
   jankurai self-audit).
3. Push the version commit. The
   [`ci.yml`](../.github/workflows/ci.yml) workflow runs the build and jankurai
   audit jobs and uploads the `repo-score` artifacts.
4. Tag the release commit with `jankurai-paper-v<version>-split.<N>`. The tag
   mirror in [`.jeryu/repo.toml`](../.jeryu/repo.toml) publishes the immutable
   tag to the public GitHub mirror.

Release builds depend on immutable tags, never branches.

## Integrity, provenance, and SBOM

- **Build integrity**: the PDF is reproducible because `latexmk` is driven
  non-interactively from committed TeX and committed data sources under
  `paper/data/`; the same inputs always produce the same `paper/jankurai.pdf`.
- **SBOM**: the build's software bill of materials is the pinned TeX Live package
  set declared in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)
  (`latexmk`, `biber`) plus the toolchain pins in `ops/ci/lib.sh`. Export it as
  `sbom.txt` at release time with `tlmgr info --only-installed > sbom.txt` and
  attach it to the release.
- **Provenance**: the jankurai audit job publishes the `repo-score` artifacts
  that prove the release passed the jankurai gate (score, caps, and findings),
  giving every release an inspectable provenance record.
- **Action pinning**: every third-party GitHub Action is pinned to a
  40-character commit SHA so the supply chain of the release pipeline itself is
  fixed.

## Rollback

If a release regresses:

1. Identify the last known-good tag
   (`jankurai-paper-v<version>-split.<N>`).
2. Re-point consumers at that immutable tag; tags are never moved or deleted.
3. Open a revert commit that restores the previous `VERSION` and `CHANGELOG.md`
   state, and add a `### Fixed` entry describing the rollback.
4. Re-run `just check` to confirm the rolled-back tree builds and audits clean
   before re-publishing.

Because tags are immutable and the TeX sources and data are committed, any prior
release PDF can be rebuilt from its tag.
