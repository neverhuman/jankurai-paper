#!/usr/bin/env bash
# Produce real lane receipts before requiring every changed-surface obligation.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
base="$(bash ops/ci/comparison-base.sh)"
mkdir -p target/jankurai
jankurai proof . --changed-from "$base" --out target/jankurai/proof-plan.json --md target/jankurai/proof-plan.md
receipt_dir="$(mktemp -d target/jankurai/proof-receipts.XXXXXX)"
jankurai prove . --plan target/jankurai/proof-plan.json --out-dir "$receipt_dir"
jankurai proof-verify . --plan target/jankurai/proof-plan.json --evidence-index target/jankurai/evidence-index.json --out target/jankurai/proof-verification.json --md target/jankurai/proof-verification.md
jq -e '.verdict == "pass" and (.issues | length == 0)' target/jankurai/proof-verification.json > /dev/null
jankurai proofbind verify . --changed-from "$base" --mode required --proof-receipts "$receipt_dir"
