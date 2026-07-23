// CI simples: valida que schema.json e data.jsonl existem, são válidos
// e que cada linha do data.jsonl respeita os campos REQUIRED do schema.
const fs = require('fs');
const path = require('path');
const assert = require('node:assert');
const test = require('node:test');

const schemaPath = path.join(__dirname, 'schema.json');
const dataPath = path.join(__dirname, 'data.jsonl');

test('schema.json deve ser um JSON válido com campos', () => {
  const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  assert.ok(Array.isArray(schema));
  assert.ok(schema.length > 0);
});

test('data.jsonl deve ter ao menos uma linha', () => {
  const lines = fs.readFileSync(dataPath, 'utf8').trim().split('\n');
  assert.ok(lines.length > 0);
});

test('cada linha do data.jsonl deve ser JSON válido e ter os campos REQUIRED', () => {
  const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  const required = schema.filter((f) => f.mode === 'REQUIRED').map((f) => f.name);
  const lines = fs.readFileSync(dataPath, 'utf8').trim().split('\n');

  for (const line of lines) {
    const row = JSON.parse(line);
    for (const field of required) {
      assert.ok(
        Object.prototype.hasOwnProperty.call(row, field) && row[field] !== null,
        `campo obrigatório "${field}" ausente na linha: ${line}`
      );
    }
  }
});