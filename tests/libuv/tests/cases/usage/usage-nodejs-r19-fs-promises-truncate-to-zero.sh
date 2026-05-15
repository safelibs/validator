#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-fs-promises-truncate-to-zero
# @title: Node.js fs.promises.truncate shrinks a file to zero bytes
# @description: Writes a 256-byte payload to a temp file via fs.promises.writeFile, asserts fs.promises.stat reports size 256, calls fs.promises.truncate on the same path with length 0, then asserts a follow-up stat reports size 0 and that fs.promises.readFile returns an empty Buffer, exercising libuv-backed truncate semantics through the promises API.
# @timeout: 60
# @tags: usage, nodejs, fs, truncate, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const path = '$tmpdir/payload.bin';
  const data = Buffer.alloc(256, 0x41);
  await fsp.writeFile(path, data);
  let st = await fsp.stat(path);
  assert.strictEqual(st.size, 256);
  await fsp.truncate(path, 0);
  st = await fsp.stat(path);
  assert.strictEqual(st.size, 0);
  const after = await fsp.readFile(path);
  assert.strictEqual(after.length, 0);
  console.log('OK truncate.size=' + st.size);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK truncate.size=0'
