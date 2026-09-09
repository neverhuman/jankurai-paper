#!/usr/bin/env bash
# CI doctor: confirms the local environment has every tool the ops/ci lanes
# depend on, with the versions pinned in ops/ci/lib.sh. Run this before pushing
# to verify your machine matches what GitHub Actions provides.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../ops/ci/lib.sh"

log "ci-doctor: checking required tools"

status=0
for tool in node npm jq gitleaks zizmor actionlint syft grype latexmk pdflatex biber jankurai; do
  if command -v "$tool" >/dev/null 2>&1; then
    log "ok: $tool ($(command -v "$tool"))"
  else
    printf '[ci] MISSING: %s\n' "$tool" >&2
    status=1
  fi
done

if command -v node >/dev/null 2>&1 && [[ "$(node -p 'process.versions.node.split(".")[0]')" != 24 ]]; then
  printf '[ci] Node 24 is required\n' >&2
  status=1
fi

log "pinned versions: texlive=$TEXLIVE_VERSION latexmk=$LATEXMK_VERSION"

if [ "$status" -ne 0 ]; then
  printf '[ci] environment does not match CI; install the tools above\n' >&2
fi
exit "$status"
