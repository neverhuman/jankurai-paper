#!/usr/bin/env bash
# Tool-adoption evidence lane for the paper arm.
#
# jankurai replaces ad-hoc tooling (manual scoring, gitleaks-only security,
# hand-rolled release/cost checklists, manual proof routing) with first-class
# subcommands. This lane runs each adopted command in CI and writes its evidence
# artifact under target/jankurai/ so the audit can prove the replacement
# actually executed. The matching artifacts are uploaded by the workflow's
# actions/upload-artifact step.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

mkdir -p target/jankurai target/jankurai/security target/jankurai/proofbind

# audit-ci / proof-routing / contract-drift / authz-matrix / agent-tool-supply
# / release-readiness / cost-budget all adopt the ratchet audit command.
log "tool-adoption: ratchet audit"
jankurai audit . --mode ratchet --baseline target/jankurai/accepted-baseline.json --json target/jankurai/repo-score.json --md target/jankurai/repo-score.md --full
# Adopted artifacts: .jankurai/repo-score.json .jankurai/repo-score.md
# target/jankurai/repair-queue.jsonl

# proofbind: changed-surface proof obligation routing.
log "tool-adoption: proofbind verify"
jankurai proofbind verify . --changed-from origin/main
# Adopted artifacts: target/jankurai/proofbind/surface-witness.json
# target/jankurai/proofbind/obligations.json

# vibe-coverage: tips-backed vibe coverage replacing manual review. The source
# corpus (agent/vibe-coverage.toml) and tips (tips/vibe_coding) are committed.
log "tool-adoption: vibe coverage"
jankurai vibe coverage --source agent/vibe-coverage.toml --tips tips/vibe_coding --json target/jankurai/vibe-coverage.json --md target/jankurai/vibe-coverage.md
# Adopted artifacts: target/jankurai/vibe-coverage.json target/jankurai/vibe-coverage.md

# security: secret + supply-chain evidence in one lane.
log "tool-adoption: security run"
jankurai security run . --out target/jankurai/security/evidence.json --script ops/ci/security-scans.sh
# Adopted artifact: target/jankurai/security/evidence.json
