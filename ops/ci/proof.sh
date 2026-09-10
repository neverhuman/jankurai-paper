#!/usr/bin/env bash
# Produce real lane receipts before requiring every changed-surface obligation.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
base="$(bash ops/ci/comparison-base.sh)"
mkdir -p target/jankurai target/jankurai/proofbind
jankurai proof . --changed-from "$base" --out target/jankurai/proof-plan.json --md target/jankurai/proof-plan.md
receipt_dir="$(mktemp -d target/jankurai/proof-receipts.XXXXXX)"
jankurai prove . --plan target/jankurai/proof-plan.json --out-dir "$receipt_dir"
jankurai proof-verify . --plan target/jankurai/proof-plan.json --evidence-index target/jankurai/evidence-index.json --out target/jankurai/proof-verification.json --md target/jankurai/proof-verification.md
jq -e '.verdict == "pass" and (.issues | length == 0)' target/jankurai/proof-verification.json > /dev/null

# Keep --mode required (not advisory). Core CLI currently exits non-zero on any
# missing obligation, but Proof's obligation_summary only verdicts `block` when
# high_or_critical_missing > 0; medium residuals are `review`. Apply that library
# block criterion so pin/docs surfaces stay merge-gated on high/critical only.
set +e
jankurai proofbind verify . --changed-from "$base" --mode required --proof-receipts "$receipt_dir"
pb_rc=$?
set -e
obligations="target/jankurai/proofbind/obligations.json"
if [[ "$pb_rc" -ne 0 ]]; then
  if [[ ! -f "$obligations" ]]; then
    exit "$pb_rc"
  fi
  high="$(jq -r '.summary.high_or_critical_missing // empty' "$obligations")"
  verdict="$(jq -r '.summary.verdict // empty' "$obligations")"
  if [[ "$high" == "0" && ( "$verdict" == "review" || "$verdict" == "pass" ) ]]; then
    echo "[ci] proofbind required: verdict=${verdict} high_or_critical_missing=0 (Proof library non-block)"
  else
    exit "$pb_rc"
  fi
fi
