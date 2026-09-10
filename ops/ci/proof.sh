#!/usr/bin/env bash
# Qualify changed-surface proof obligations with proofbind (Core-compatible).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
base="$(bash ops/ci/comparison-base.sh)"
mkdir -p target/jankurai/proofbind
jankurai proofbind verify . --changed-from "$base"
