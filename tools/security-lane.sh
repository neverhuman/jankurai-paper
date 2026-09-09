#!/usr/bin/env bash
# Canonical security lane wrapper for jankurai-paper.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p target

echo "[security] secret scan: gitleaks detect"
gitleaks detect --source . --no-banner --redact

echo "[security] workflow lint: actionlint"
actionlint

echo "[security] SBOM / provenance: hash published paper sources"
find paper docs agent README.md AGENTS.md -type f | sort | xargs sha256sum > target/sbom.txt
echo "[security] sbom written to target/sbom.txt"
