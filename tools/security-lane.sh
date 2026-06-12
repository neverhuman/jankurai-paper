#!/usr/bin/env bash
# Canonical operational security lane for the paper arm.
# This is the single source of truth for the security command posture; both
# `just security` and the CI security job (ops/ci/security.sh) run this script,
# so local and CI execute the exact same commands.
#
# This repo ships no dependency manifest (no Cargo.toml/package.json), so the
# operational security surface is committed-secret detection, CI workflow
# hardening (action pinning), and a software bill of materials for the build
# toolchain.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

mkdir -p target/jankurai/security

# Secret scanning: detect committed credentials in paper sources and data.
echo "[security] gitleaks detect (secret scan)"
gitleaks detect --source . --no-banner --redact --report-format sarif --report-path target/jankurai/security/gitleaks.sarif

# Operational security evidence: jankurai runs the configured scanners (secret,
# dependency, SBOM/provenance) and writes a single validated evidence artifact.
echo "[security] jankurai security run (operational evidence)"
jankurai security run . --out target/jankurai/security/evidence.json

# Workflow supply-chain lint: actionlint validates the workflow grammar and
# zizmor audits it for supply-chain hardening (every CI action must stay pinned
# to a full commit SHA). The paper ships a real .github/workflows CI surface, so
# this workflow audit is operational, not advisory.
echo "[security] actionlint + zizmor workflow lint"
actionlint .github/workflows
zizmor .github/workflows --format sarif > target/jankurai/security/zizmor.sarif

# SBOM / provenance: record the build toolchain bill of materials so releases
# have a software bill of materials and a reproducible provenance record.
echo "[security] syft SBOM (build toolchain)"
syft dir:. --output cyclonedx-json=target/jankurai/security/sbom.cyclonedx.json
