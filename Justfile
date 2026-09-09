# jankurai-paper root command surface.
# One-command setup and validation lanes for agents and CI.
# Every lane below is deterministic and runnable from the repo root.
# This repo builds the jankurai TeX paper; the proof loop is the LaTeX build.

# Default: list available lanes.
default:
    @just --list

# Install the locked CI tools and verify the required TeX installation.
setup:
    npm ci
    latexmk -version

# Alias for setup so `just install` and `just bootstrap` also resolve.
install: setup

bootstrap: setup

# Deterministic fast lane: the narrowest proof loop for agent iteration.
# Builds the paper PDF reproducibly (incremental via latexmk's .fdb_latexmk
# recorder cache), then runs a changed-surface, target-only jankurai self-audit.
fast:
    latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=paper paper/jankurai.tex
    jankurai audit . --changed-fast --no-score-history --json target/jankurai/fast-score.json --md target/jankurai/fast-score.md --timings-json target/jankurai/audit-fast.json

# Full self-audit writing the canonical repo-score artifacts.
score:
    jankurai audit . --no-score-history --json .jankurai/repo-score.json --md .jankurai/repo-score.md

# Generate an agent context pack: a token-bounded routing brief for the next
# agent, derived from the owner/test maps and docs.
context-pack:
    jankurai context-pack . --out target/jankurai/context-pack.json --md target/jankurai/context-pack.md

# Run the full local check: build the paper, scan for secrets, then self-audit.
check:
    bash ops/ci/quality-gates.sh

# Verify is an alias of check for agents that look for a `verify` lane.
verify: check

# Security lane: secret scanning, CI workflow supply-chain lint, and an SBOM /
# provenance record. This repo ships no dependency manifest, so the security
# surface is committed secrets, SHA-pinned CI actions, and a build-toolchain SBOM.
# gitleaks detects committed secrets; jankurai security run writes the validated
# operational evidence artifact.
security:
    bash ops/ci/security.sh

# Build the paper PDF from the canonical TeX source.
build:
    latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=paper paper/jankurai.tex

# Run the paper build as the test lane (a clean build is the test).
test:
    bash ops/ci/required.sh

# Jankurai self-audit lane: writes the repo-score artifacts that CI uploads.
# `repo-score` is the published artifact name consumed by the audit job.
audit:
    bash ops/ci/audit.sh

# Print the declared version.
versions:
    cat VERSION
