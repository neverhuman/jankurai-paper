// Public badge provenance is separate from supervised-execution evidence.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { parseUniqueJson } from './json.mjs';

export function validateBadgeSource(text, provenance) {
  const report = parseUniqueJson(text);
  const decision = report.decision;
  if (createHash('sha256').update(text).digest('hex') !== provenance.report_sha256 ||
      report.report_fingerprint !== provenance.report_fingerprint)
    throw new Error('badge report differs from its recorded provenance');
  for (const field of ['audited_commit', 'audited_tree', 'auditor_commit', 'auditor_tree'])
    if (!/^[a-f0-9]{40}$/.test(provenance[field])) throw new Error(`invalid ${field}`);
  if (!/^[a-f0-9]{64}$/.test(provenance.auditor_binary_sha256))
    throw new Error('missing auditor binary identity');
  if (!/^[a-f0-9]{7,40}$/.test(report.git?.head) || !provenance.audited_commit.startsWith(report.git.head))
    throw new Error('badge report does not match the audited revision');
  if (report.dirty_worktree !== false || report.git?.dirty_worktree !== false ||
      report.scope?.mode !== 'full' || report.scope.paths.length !== 0 || report.git.mode !== 'full')
    throw new Error('public badge requires a clean full audit');
  if (report.policy?.mode !== 'standard' || provenance.mode !== 'standard' || provenance.scope !== 'full' ||
      decision?.status !== 'pass' || decision.passed !== true || decision.hard_findings !== 0 ||
      !Number.isInteger(report.score) || !Number.isInteger(decision.minimum_score) ||
      !Number.isInteger(report.policy.minimum_score) ||
      decision.minimum_score < report.policy.minimum_score || report.score < decision.minimum_score ||
      !Array.isArray(report.findings) || report.findings.some(f => f.hardness === 'hard'))
    throw new Error('public badge requires a successful standard audit without hard findings');
  return report;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const provenance = parseUniqueJson(readFileSync('agent/baselines/main.repo-score.provenance.json', 'utf8'));
  validateBadgeSource(readFileSync('agent/baselines/main.repo-score.json', 'utf8'), provenance);
  const tree = execFileSync('git', ['rev-parse', `${provenance.audited_commit}^{tree}`], { encoding: 'utf8' }).trim();
  if (tree !== provenance.audited_tree) throw new Error('audited source tree does not match provenance');
  execFileSync('git', ['merge-base', '--is-ancestor', provenance.audited_commit, 'HEAD']);
  console.log(`verified badge source ${provenance.audited_commit}`);
}
