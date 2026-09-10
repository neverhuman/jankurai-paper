#!/usr/bin/env bash
# One blocking scan per tool. Retain each run, including failed artifacts.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p target/jankurai/security
run_dir="$(mktemp -d target/jankurai/security/run.XXXXXX)"
started="$(date +%s)"
# Prior runs remain in run.*; stable names must never stand in for new output.
rm -f target/jankurai/security/{gitleaks.sarif,zizmor.sarif,sbom.json}
scan() {
  local tool="$1"; shift
  local status=ran result=0
  "$@" || { result=$?; status=failed; }
  jq -cn --arg tool "$tool" --arg command "$*" --arg status "$status" --argjson result "$result" \
    '{label:$tool,tool:$tool,shell_command:$command,status:$status,exit_code:$result,advisory:false}' \
    | sed 's/^/jankurai-security-step=/'
  return "$result"
}
zizmor_scan() {
  zizmor --no-progress --format sarif .github/workflows > "$run_dir/zizmor.sarif" || return
  # SARIF mode exits zero for findings: require complete, empty result sets too.
  jq -e '.version == "2.1.0" and (.runs | type == "array" and length > 0) and
    all(.runs[]; (.results | type == "array" and length == 0) and
      all(.invocations[]?; .executionSuccessful != false))' "$run_dir/zizmor.sarif" > /dev/null
}
scan gitleaks gitleaks detect --source . --no-banner --redact \
  --report-format sarif --report-path "$run_dir/gitleaks.sarif"
scan zizmor zizmor_scan
scan actionlint actionlint .github/workflows/*.yml
if [[ -f Cargo.toml ]]; then
  scan cargo-audit cargo audit
  scan cargo-deny cargo deny check advisories bans sources
fi
if [[ -f package.json ]]; then
  [[ -f package-lock.json ]] || { echo 'package.json requires a locked dependency inventory' >&2; exit 1; }
  scan npm npm audit --audit-level=high
fi
scan syft syft scan dir:. --exclude './target/**' --exclude './.git/**' --exclude './node_modules/**' \
  -o "cyclonedx-json=$run_dir/sbom.json"
scan sbom-validation node ops/ci/validate-sbom.mjs "$run_dir/sbom.json" "$started"
scan grype grype "sbom:$run_dir/sbom.json" --fail-on high
for artifact in gitleaks.sarif zizmor.sarif sbom.json; do
  [[ -s "$run_dir/$artifact" && ! -L "$run_dir/$artifact" ]]
  cp "$run_dir/$artifact" "target/jankurai/security/$artifact"
done
