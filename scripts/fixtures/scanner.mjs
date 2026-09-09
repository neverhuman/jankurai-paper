#!/usr/bin/env node
// Controlled subprocess fixture, installed only in temporary test directories.
import { appendFileSync, writeFileSync, symlinkSync, utimesSync } from 'node:fs';
import { basename, resolve } from 'node:path';
const tool = basename(process.argv[1]);
const args = process.argv.slice(2);
appendFileSync('calls.jsonl', JSON.stringify([tool, args]) + '\n');
if (process.env.FAIL_TOOL === tool) process.exit(23);
if (tool === 'gitleaks' && !process.env.MISSING_SARIF)
  writeFileSync(args[args.indexOf('--report-path') + 1], '{"version":"2.1.0","runs":[]}');
if (tool === 'zizmor') {
  const results = process.env.SARIF_FINDING ? [{ ruleId: 'unsafe-workflow', level: 'warning' }] : [];
  console.log(JSON.stringify({ version: '2.1.0', runs: [{ results }] }));
}
if (tool === 'syft') {
  const path = args[args.indexOf('-o') + 1].split('=')[1];
  const kind = process.env.SBOM_KIND ?? 'valid';
  if (kind === 'missing') process.exit(0);
  if (kind === 'symlink') { symlinkSync(resolve('old-sbom.json'), path); process.exit(0); }
  const data = { bomFormat: 'CycloneDX', specVersion: '1.6', version: 1,
    serialNumber: 'urn:uuid:870a5fb2-7af4-45d6-aaf0-096d9a604524',
    metadata: { timestamp: kind === 'stale' ? '2000-01-01T00:00:00Z' : new Date().toISOString(),
      component: { type: 'file', name: '.' },
      tools: { components: [{ type: 'application', name: 'syft', version: '1.40.0' }] } },
    components: [{ type: 'library', name: 'fixture', version: '1.0.0' }] };
  if (kind === 'schema') data.components[0].type = 'not-a-component-type';
  if (kind === 'producer') data.metadata.tools.components[0].version = '0.0.0';
  if (kind === 'inventory') delete data.components;
  if (kind === 'format') data.specVersion = '1.5';
  if (kind === 'email') data.metadata.authors = [{ name: 'fixture', email: 'not an email' }];
  if (kind === 'iri') data.externalReferences = [{ type: 'website', url: 'http://bad host.invalid' }];
  if (kind === 'timestamp') delete data.metadata.timestamp;
  let text = kind === 'text' ? 'old hash list' : JSON.stringify(data);
  if (kind === 'duplicate') text = text.replace('"version":1', '"version":0,"version":1');
  writeFileSync(path, text);
  if (kind === 'mtime') utimesSync(path, 0, 0);
}
