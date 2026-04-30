#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-appendfile-concurrent
# @title: Node.js fs.appendFile concurrent writes consistency
# @description: Issues many concurrent fs.appendFile writes to one file and verifies the resulting bytes contain every line exactly once.
# @timeout: 180
# @tags: usage, event-loop, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

OUT_FILE="$tmpdir/append.log" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const fs = require('fs');
const fsp = require('fs/promises');

const target = process.env.OUT_FILE;
const N = 50;

(async () => {
  // Truncate target.
  await fsp.writeFile(target, '');
  const writes = [];
  for (let i = 0; i < N; i++) {
    writes.push(fsp.appendFile(target, `line-${i.toString().padStart(3, '0')}\n`));
  }
  await Promise.all(writes);

  const body = await fsp.readFile(target, 'utf8');
  const lines = body.split('\n').filter(Boolean).sort();
  assert.strictEqual(lines.length, N, 'line count: ' + lines.length);
  for (let i = 0; i < N; i++) {
    const want = `line-${i.toString().padStart(3, '0')}`;
    assert.strictEqual(lines[i], want, `missing ${want}`);
  }
  const bytes = fs.statSync(target).size;
  console.log('OK appendFile', N, bytes);
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK appendFile 50'
