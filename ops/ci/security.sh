#!/usr/bin/env bash
# Security lane (CI entrypoint): secret scanning, workflow supply-chain linting,
# and an SBOM / provenance record for the paper sources and build inputs.
# This repo ships no dependency manifest (no Cargo.toml/package.json), so the
# operational security surface is committed-secret detection, CI workflow
# hardening, and a software bill of materials for the build toolchain.
#
# The actual command posture lives in tools/security-lane.sh, the canonical
# single source of truth that `just security` also runs, so local and CI execute
# the exact same security commands. This thin wrapper adds the CI-side artifact
# assertions on top of that shared lane.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

log "security lane: running canonical tools/security-lane.sh"
bash tools/security-lane.sh

assert_artifact target/jankurai/security/evidence.json
assert_artifact target/jankurai/security/gitleaks.sarif
assert_artifact target/jankurai/security/zizmor.sarif
assert_artifact target/jankurai/security/sbom.cyclonedx.json
