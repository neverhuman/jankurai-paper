// Validate a fresh Syft inventory using the pinned, offline CycloneDX schema.
import { readFileSync, readdirSync, lstatSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import addInternationalFormats from 'ajv-formats-draft2019';

import { parseUniqueJson } from './json.mjs';

export function validateSbom(path, started) {
  const info = lstatSync(path);
  if (!info.isFile() || info.size === 0 || info.mtimeMs < started * 1000)
    throw new Error('SBOM must be a fresh, nonempty regular file');
  const document = parseUniqueJson(readFileSync(path, 'utf8'));
  const dir = new URL('./schemas/', import.meta.url);
  const schemas = readdirSync(dir).filter(p => p.endsWith('.schema.json'))
    .map(p => JSON.parse(readFileSync(new URL(p, dir), 'utf8')));
  const ajv = new Ajv({ strict: false, schemas });
  addFormats(ajv);
  addInternationalFormats(ajv);
  // The IRI parser normalizes spaces; a serialized schema value must be valid
  // before normalization, so reject forbidden ASCII characters explicitly.
  const iriReference = ajv.formats['iri-reference'];
  ajv.addFormat('iri-reference', value =>
    !/[\u0000-\u0020\u007f<>"{}|\\^`]/u.test(value) && iriReference(value));
  const validate = ajv.getSchema('http://cyclonedx.org/schema/bom-1.6.schema.json');
  if (!validate(document)) throw new Error(ajv.errorsText(validate.errors));
  if (document.specVersion !== '1.6') throw new Error('expected CycloneDX 1.6');
  const timestamp = Date.parse(document.metadata?.timestamp);
  if (!Number.isFinite(timestamp) || timestamp < started * 1000 || timestamp > Date.now())
    throw new Error('SBOM timestamp is outside this scan');
  if (!document.metadata?.tools?.components?.some(p => p.name === 'syft' && p.version === '1.40.0'))
    throw new Error('SBOM must identify the pinned Syft 1.40.0 producer');
  if (!document.serialNumber || !Array.isArray(document.components))
    throw new Error('SBOM requires an identity and an explicit component inventory');
  console.log(`validated fresh CycloneDX 1.6 SBOM: ${document.components.length} components`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const started = Number(process.argv[3]);
  if (!Number.isSafeInteger(started) || started <= 0) throw new Error('invalid scan start time');
  validateSbom(process.argv[2], started);
}
