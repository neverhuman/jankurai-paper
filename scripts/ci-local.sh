#!/usr/bin/env bash
# Local CI entrypoint. Mirrors the GitHub Actions lanes so a green local run
# means a green CI run. Each lane delegates to ops/ci/<lane>.sh.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

lane="${1:-required}"
case "$lane" in
  required)       bash ops/ci/required.sh ;;
  fast)           bash ops/ci/fast.sh ;;
  security)       bash ops/ci/security.sh ;;
  audit)          bash ops/ci/audit.sh ;;
  tool-adoption)  bash ops/ci/tool-adoption.sh ;;
  gates)          bash ops/ci/quality-gates.sh ;;
  *) echo "usage: $0 {required|fast|security|audit|tool-adoption|gates}" >&2; exit 2 ;;
esac
