#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
node --input-type=module - <<'JS_RESULTS'
import { parseUniqueJson } from './ops/ci/json.mjs';
const jobs = parseUniqueJson(process.env.NEEDS_JSON);
if (jobs === null || typeof jobs !== 'object' || Array.isArray(jobs) ||
    Object.keys(jobs).length !== 1 || !Object.hasOwn(jobs, 'quality')) {
  throw new Error('required jobs must contain exactly quality');
}
if (jobs.quality === null || typeof jobs.quality !== 'object' ||
    Array.isArray(jobs.quality) || jobs.quality.result !== 'success') {
  throw new Error('quality must finish successfully');
}
console.log('all required lanes passed: quality');
JS_RESULTS
