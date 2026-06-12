# Changelog

All notable changes to jankurai-paper are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The authoritative version string lives in [`VERSION`](VERSION).

## [Unreleased]

### Added

- Root `Justfile` command surface with `setup`, `fast`, `check`, `verify`, and
  `audit` lanes for one-command setup and validation.
- GitHub Actions CI (`.github/workflows/ci.yml`) with a deterministic build/fast
  lane and a jankurai audit lane; all third-party actions pinned to commit SHAs.
- `ops/ci/{lib,fast,audit,required,security,quality-gates,tool-adoption}.sh`
  lane scripts shared by CI and `scripts/ci-local.sh` so local and CI runs
  execute the same commands.
- `ops/git-hooks/pre-push` mandatory gate and `scripts/ci-doctor.sh` environment
  doctor for CI/local parity.
- Security lane (`tools/security-lane.sh`, `ops/ci/security.sh`): gitleaks secret
  scan, zizmor workflow lint, and a CycloneDX SBOM, with SARIF upload in CI.
- Tool-adoption evidence lane: ratchet audit, proofbind verify, vibe coverage,
  and `jankurai security run` wired into CI with uploaded artifacts.
- Agent-readable documentation: `README.md`, `docs/architecture.md`,
  `docs/boundaries.md`, `docs/testing.md`, `docs/release.md`, and
  `docs/exceptions.md`.
- `agent/audit-policy.toml` scoped for this paper repo (excludes the `tips/`
  teaching corpus and transient build output).
- `agent/{boundaries,security-policy,tool-adoption,badge}.toml`,
  `agent/jankurai-badge.svg`, and machine-readable contract schemas under
  `schemas/` and `contracts/json-schema/` for the paper data surface.
- `ops/AGENTS.md` and `contracts/AGENTS.md` local routing guidance.
- `VERSION` and this `CHANGELOG.md` for release readiness.

### Changed

- Re-scoped `agent/owner-map.json`, `agent/test-map.json`, and
  `agent/generated-zones.toml` to the paths that actually exist in this repo,
  and added generated-zone entries for the paper's generated TeX tables and
  their data contracts.

## [1.7.0] - 2026-06-12

### Added

- Initial split-family extraction of the jankurai TeX paper, paper data, and
  paper build lane.
