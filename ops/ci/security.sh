#!/usr/bin/env bash
# Local and hosted CI use the same strict scanner entrypoint.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"
log "security lane: required scanners and validated CycloneDX"
jankurai security run . --strict --profile ci --script tools/security-lane.sh \
  --out target/jankurai/security/evidence.json
for artifact in evidence.json gitleaks.sarif zizmor.sarif sbom.json; do
  assert_artifact "target/jankurai/security/$artifact"
done
