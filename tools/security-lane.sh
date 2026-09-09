#!/usr/bin/env bash
# Shared, blocking scanner implementation for local and hosted CI.
set -euo pipefail
exec bash "$(dirname "${BASH_SOURCE[0]}")/../ops/ci/security-scans.sh"
