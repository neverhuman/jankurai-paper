#!/usr/bin/env bash
# Required lane: the lightweight gate that must pass on every push.
# Builds the paper PDF from its canonical TeX source.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

log "required lane: latexmk paper build"
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=paper paper/jankurai.tex
