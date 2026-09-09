#!/usr/bin/env bash
# Required lane: the lightweight gate that must pass on every push.
# Builds the paper PDF from its canonical TeX source.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

log "required lane: CI rejection and artifact freshness tests"
npm test

log "required lane: latexmk paper build"
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=paper paper/jankurai.tex
if [[ ! -f paper/jankurai.pdf || -L paper/jankurai.pdf || ! -s paper/jankurai.pdf ]]; then
  printf '[ci] paper build did not produce a nonempty regular PDF\n' >&2
  exit 1
fi
mkdir -p target/jankurai
sha256sum paper/jankurai.pdf > target/jankurai/paper-build.sha256
