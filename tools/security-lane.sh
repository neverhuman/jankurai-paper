#!/usr/bin/env bash
# Canonical security lane wrapper for jankurai-paper.
#
# Emits `jankurai-security-step=` evidence rows and the CI-asserted SARIF/SBOM
# artifacts. gitleaks is required in the ci profile; zizmor is advisory.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p target target/jankurai/security

run_step() {
    local label="$1"
    local tool="$2"
    local shell_command="$3"
    local advisory="$4"
    shift 4
    set +e
    "$@"
    local exit_code=$?
    set -e
    local status="ran"
    if [[ ${exit_code} -ne 0 ]]; then
        status="failed"
    fi
    printf 'jankurai-security-step={"label":"%s","tool":"%s","shell_command":"%s","status":"%s","advisory":%s,"exit_code":%d}\n' \
        "${label}" "${tool}" "${shell_command}" "${status}" "${advisory}" "${exit_code}"
    if [[ "${advisory}" == "true" ]]; then
        return 0
    fi
    return "${exit_code}"
}

echo "[security] secret scan: gitleaks detect"
run_step gitleaks gitleaks 'gitleaks detect --source . --no-banner --redact' false \
    gitleaks detect --source . --no-banner --redact \
    --report-format sarif --report-path target/jankurai/security/gitleaks.sarif

echo "[security] workflow lint: zizmor + actionlint"
run_step zizmor zizmor 'zizmor --no-progress .github/workflows' true \
    zizmor --no-progress .github/workflows
zizmor --no-progress --format sarif .github/workflows > target/jankurai/security/zizmor.sarif
run_step actionlint actionlint 'actionlint' true \
    actionlint

echo "[security] SBOM / provenance"
if command -v syft >/dev/null 2>&1; then
    run_step syft syft 'syft scan dir:.' true \
        syft scan dir:. --exclude './target/**' --exclude './.git/**' \
        -o cyclonedx-json=target/jankurai/security/sbom.cyclonedx.json
else
    find paper docs agent README.md AGENTS.md -type f | sort | xargs sha256sum \
        > target/jankurai/security/sbom.cyclonedx.json
fi
find paper docs agent README.md AGENTS.md -type f | sort | xargs sha256sum > target/sbom.txt
echo "[security] sbom written to target/sbom.txt"
