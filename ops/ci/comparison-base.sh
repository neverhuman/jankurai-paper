#!/usr/bin/env bash
# Compare a PR with protected main; on main, qualify the change from its parent.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
base="$(git rev-parse --verify 'refs/remotes/origin/main^{commit}')"
head="$(git rev-parse HEAD)"
if [[ "$base" == "$head" ]]; then
  base="$(git rev-parse --verify 'HEAD^1^{commit}')"
fi
git merge-base --is-ancestor "$base" "$head"
printf '%s\n' "$base"
