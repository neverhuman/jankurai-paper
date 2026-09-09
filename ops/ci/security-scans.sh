#!/usr/bin/env bash
# Compatibility entrypoint; actual scanner commands live in the canonical lane.
set -euo pipefail
exec bash "$(dirname "${BASH_SOURCE[0]}")/../../tools/security-lane.sh"
