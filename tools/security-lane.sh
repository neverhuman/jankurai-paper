#!/usr/bin/env bash
# Compatibility entrypoint for the canonical scanner lane.
set -euo pipefail
exec bash "$(dirname "${BASH_SOURCE[0]}")/../ops/ci/security-scans.sh" "$@"
