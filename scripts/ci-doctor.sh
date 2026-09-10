#!/usr/bin/env bash
# CI doctor checks required tools and Node's major version. Hosted setup selects
# tools in github-setup.sh and ci.yml; this check is not a provenance receipt.
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

if command -v latexmk >/dev/null 2>&1; then latexmk -version; fi
if command -v pdflatex >/dev/null 2>&1; then pdflatex --version; fi

if [ "$status" -ne 0 ]; then
  printf '[ci] environment does not match CI; install the tools above\n' >&2
fi
exit "$status"
