import assert from 'node:assert/strict';
import { test } from 'node:test';
import { cpSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync, chmodSync,
  rmSync, symlinkSync, existsSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { parseUniqueJson } from '../ops/ci/json.mjs';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const aggregate = needs => spawnSync('bash', [join(root, 'ops/ci/aggregate.sh')], {
  env: { ...process.env, NEEDS_JSON: needs }, encoding: 'utf8' });

test('aggregate accepts exactly the successful quality lane', () => {
  assert.equal(aggregate('{"quality":{"result":"success","outputs":{}}}').status, 0);
  const invalid = ['{"quality":{"result":"failure"},"quality":{"result":"success"}}', '{}', '[]', 'null', '42', '"success"', '{',
    '{"other":{"result":"success"}}', '{"quality":null}', '{"quality":[]}', '{"quality":{}}',
    '{"quality":{"result":"success"},"extra":{"result":"success"}}',
    ...['failure', 'cancelled', 'skipped', 'neutral', '', null].map(result => JSON.stringify({ quality: { result } }))];
  for (const value of invalid) assert.notEqual(aggregate(value).status, 0, value);
});
test('removing or renaming the actual workflow dependency cannot pass', () => {
  const workflow = readFileSync(join(root, '.github/workflows/ci.yml'), 'utf8');
  assert.match(workflow, /^  quality:$/m);
  assert.match(workflow, /^    needs: quality$/m);
  assert.ok(workflow.includes('NEEDS_JSON: ${{ toJSON(needs) }}'));
  for (const changed of [workflow.replace('    needs: quality\n', ''), workflow.replaceAll('quality', 'renamed')]) {
    const required = changed.split('  required:\n')[1].split('  publish-ci-tag:')[0];
    const dependencies = [...required.matchAll(/^    needs: (\w+)$/gm)].map(m => m[1]);
    const needs = Object.fromEntries(dependencies.map(name => [name, { result: 'success' }]));
    assert.notEqual(aggregate(JSON.stringify(needs)).status, 0);
  }
});
test('JSON rejects repeated keys at every object depth without confusing strings or arrays', () => {
  assert.deepEqual(parseUniqueJson('{"a":[{"b":1},{"b":2}],"text":"{\\\"a\\\":1}"}'),
    { a: [{ b: 1 }, { b: 2 }], text: '{"a":1}' });
  for (const value of ['{"a":1,"a":2}', '{"a":[{"b":1,"b":2}]}', '{'])
    assert.throws(() => parseUniqueJson(value));
});
function fixture(t) {
  const cwd = mkdtempSync(join(tmpdir(), 'jankurai-ci-test-'));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  for (const dir of ['ops', 'tools']) cpSync(join(root, dir), join(cwd, dir), { recursive: true });
  symlinkSync(join(root, 'node_modules'), join(cwd, 'node_modules'));
  mkdirSync(join(cwd, '.github/workflows'), { recursive: true });
  writeFileSync(join(cwd, '.github/workflows/ci.yml'), 'name: fixture\n');
  const bin = join(cwd, 'bin'); mkdirSync(bin);
  for (const name of ['gitleaks', 'zizmor', 'actionlint', 'syft', 'grype', 'cargo', 'npm', 'jankurai']) {
    const file = join(bin, name);
    cpSync(join(root, 'scripts/fixtures/scanner.mjs'), file); chmodSync(file, 0o755);
  }
  const env = { ...process.env, PATH: `${bin}:${process.env.PATH}` };
  return { cwd, bin, env,
    run: (extra = {}, script = 'tools/security-lane.sh') => spawnSync('bash', [script], {
      cwd, env: { ...env, ...extra }, encoding: 'utf8' }),
    calls: () => readFileSync(join(cwd, 'calls.jsonl'), 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse) };
}
const steps = result => result.stdout.split('\n').filter(s => s.startsWith('jankurai-security-step='))
  .map(s => JSON.parse(s.slice('jankurai-security-step='.length)));

test('success runs each scanner once and publishes a validated inventory', t => {
  const f = fixture(t); const result = f.run();
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.deepEqual(f.calls().map(c => c[0]), ['gitleaks', 'zizmor', 'actionlint', 'syft', 'grype']);
  assert.equal(steps(result).length, 6);
  assert.ok(steps(result).every(s => s.exit_code === 0 && s.advisory === false));
  assert.equal(JSON.parse(readFileSync(join(f.cwd, 'target/jankurai/security/sbom.cyclonedx.json'))).bomFormat, 'CycloneDX');
});
for (const tool of ['gitleaks', 'zizmor', 'actionlint', 'syft', 'grype']) {
  test(`${tool} failure blocks and preserves its actual outcome`, t => {
    const f = fixture(t); const result = f.run({ FAIL_TOOL: tool });
    assert.equal(result.status, 23, result.stdout + result.stderr);
    assert.equal(steps(result).at(-1).tool, tool);
    assert.equal(steps(result).at(-1).status, 'failed');
    assert.equal(steps(result).at(-1).exit_code, 23);
    assert.equal(steps(result).at(-1).advisory, false);
    assert.equal(existsSync(join(f.cwd, 'target/jankurai/security/sbom.cyclonedx.json')), false);
  });
}
test('missing Syft blocks without finding another system copy', t => {
  const f = fixture(t); rmSync(join(f.bin, 'syft'));
  for (const name of ['bash', 'dirname', 'mkdir', 'mktemp', 'date', 'rm', 'jq', 'sed', 'node']) {
    const located = spawnSync('which', [name], { encoding: 'utf8' }); assert.equal(located.status, 0);
    symlinkSync(located.stdout.trim(), join(f.bin, name));
  }
  const result = f.run({ PATH: f.bin });
  assert.equal(result.status, 127, result.stdout + result.stderr);
});
test('zero-exit SARIF findings block and remain available for inspection', t => {
  const f = fixture(t); const result = f.run({ SARIF_FINDING: '1' });
  assert.notEqual(result.status, 0);
  assert.ok(!f.calls().some(c => c[0] === 'syft'));
  assert.ok(readdirSync(join(f.cwd, 'target/jankurai/security')).some(p => p.startsWith('run.')));
});
for (const kind of ['missing', 'text', 'schema', 'stale', 'mtime', 'producer', 'inventory', 'format', 'timestamp', 'duplicate', 'symlink', 'email', 'iri']) {
  test(`${kind} SBOM blocks before Grype and cannot reuse the previous inventory`, t => {
    const f = fixture(t); const stable = join(f.cwd, 'target/jankurai/security/sbom.cyclonedx.json');
    mkdirSync(dirname(stable), { recursive: true }); writeFileSync(stable, '{"bomFormat":"CycloneDX"}');
    writeFileSync(join(f.cwd, 'old-sbom.json'), '{"bomFormat":"CycloneDX"}');
    const result = f.run({ SBOM_KIND: kind });
    assert.notEqual(result.status, 0, result.stdout + result.stderr);
    assert.ok(!f.calls().some(c => c[0] === 'grype')); assert.equal(existsSync(stable), false);
  });
}
test('zero-exit scanner with missing SARIF cannot pass', t => {
  const f = fixture(t); assert.notEqual(f.run({ MISSING_SARIF: '1' }).status, 0);
});
test('manifest scanners block and Node requires a lock', t => {
  const f = fixture(t); writeFileSync(join(f.cwd, 'Cargo.toml'), '[package]\nname="fixture"\nversion="1.0.0"\n');
  assert.equal(f.run({ FAIL_TOOL: 'cargo' }).status, 23); rmSync(join(f.cwd, 'Cargo.toml'));
  writeFileSync(join(f.cwd, 'package.json'), '{"name":"fixture"}');
  assert.notEqual(f.run().status, 0); writeFileSync(join(f.cwd, 'package-lock.json'), '{}');
  assert.equal(f.run({ FAIL_TOOL: 'npm' }).status, 23);
});
test('strict security entrypoint calls the auditor once and propagates failure', t => {
  const f = fixture(t); const result = f.run({ FAIL_TOOL: 'jankurai' }, 'ops/ci/security.sh');
  assert.equal(result.status, 23); const calls = f.calls(); assert.equal(calls.length, 1);
  assert.equal(calls[0][0], 'jankurai'); assert.ok(calls[0][1].includes('--strict')); assert.ok(calls[0][1].includes('ci'));
});
test('adoption invokes real policy commands and stops on auditor failure', t => {
  const f = fixture(t); const source = readFileSync(join(f.cwd, 'ops/ci/tool-adoption.sh'), 'utf8');
  assert.ok(source.includes('bash ops/ci/proof.sh')); assert.ok(source.includes('--mode ratchet'));
  assert.ok(readFileSync(join(f.cwd, 'ops/ci/proof.sh'), 'utf8').includes('--mode required'));
  writeFileSync(join(f.cwd, 'ops/ci/proof.sh'), '#!/usr/bin/env bash\nset -euo pipefail\njankurai proof .\n');
  const result = f.run({ FAIL_TOOL: 'jankurai' }, 'ops/ci/tool-adoption.sh');
  assert.equal(result.status, 23); assert.equal(f.calls().length, 1);
});


test('comparison base checks actual PR, resulting-main, and divergent commit graphs', t => {
  // A temporary bare repository exercises Git ancestry without a worktree.
  const cwd = mkdtempSync(join(tmpdir(), 'jankurai-base-test-'));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  mkdirSync(join(cwd, 'ops/ci'), { recursive: true });
  cpSync(join(root, 'ops/ci/comparison-base.sh'), join(cwd, 'ops/ci/comparison-base.sh'));
  const env = { ...process.env, HOME: cwd, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: '/dev/null',
    GIT_AUTHOR_NAME: 'CI fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid',
    GIT_COMMITTER_NAME: 'CI fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' };
  const git = (args, input) => {
    const result = spawnSync('git', args, { cwd, env, input, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr); return result.stdout.trim();
  };
  git(['init', '--bare', '-b', 'main']);
  const tree = git(['mktree'], '');
  const base = git(['commit-tree', tree, '-m', 'base']);
  const head = git(['commit-tree', tree, '-p', base, '-m', 'candidate']);
  const divergent = git(['commit-tree', tree, '-p', base, '-m', 'other branch']);
  git(['update-ref', 'refs/heads/main', head]);
  git(['update-ref', 'refs/remotes/origin/main', base]);
  const compare = () => spawnSync('bash', ['ops/ci/comparison-base.sh'], { cwd, env, encoding: 'utf8' });
  assert.equal(compare().stdout.trim(), base);
  git(['update-ref', 'refs/remotes/origin/main', head]);
  assert.equal(compare().stdout.trim(), base);
  git(['update-ref', 'refs/remotes/origin/main', divergent]);
  assert.notEqual(compare().status, 0);
  git(['update-ref', '-d', 'refs/remotes/origin/main']);
  assert.notEqual(compare().status, 0);
});
