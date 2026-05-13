#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-fs-promises-copyfile-bytes-match
# @title: Node.js fs.promises.copyFile duplicates a binary payload exactly into a new path
# @description: Writes 256 bytes (0x00..0xff) to a source file, calls fs.promises.copyFile into a sibling destination, reads both back via fs.promises.readFile and asserts the two buffers are byte-for-byte equal and exactly 256 bytes long — exercising Node.js's libuv copy_file path.
# @timeout: 60
# @tags: usage, nodejs, fs, copyfile
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const src = '$tmpdir/src.bin';
  const dst = '$tmpdir/dst.bin';
  const payload = Buffer.alloc(256);
  for (let i = 0; i < 256; i++) payload[i] = i;
  await fsp.writeFile(src, payload);
  await fsp.copyFile(src, dst);
  const a = await fsp.readFile(src);
  const b = await fsp.readFile(dst);
  assert.strictEqual(a.length, 256);
  assert.strictEqual(b.length, 256);
  assert.ok(a.equals(b), 'bytes differ');
  console.log('OK copyFile.bytes');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK copyFile.bytes'
