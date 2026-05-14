#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-fs-promises-write-read-sha256-roundtrip
# @title: Node.js fs.promises writeFile + readFile preserves bytes verified by SHA-256
# @description: Writes a 1024-byte deterministic payload to a temp file via fs.promises.writeFile, reads it back via fs.promises.readFile, and asserts the SHA-256 hex digest of the read buffer equals the SHA-256 hex digest of the original payload, exercising libuv-backed async file I/O via promises.
# @timeout: 60
# @tags: usage, nodejs, fs, sha256, roundtrip, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
const crypto = require('crypto');
(async () => {
  const buf = Buffer.alloc(1024);
  for (let i = 0; i < buf.length; i++) buf[i] = (i * 7) & 0xff;
  const path = '$tmpdir/payload.bin';
  await fsp.writeFile(path, buf);
  const read = await fsp.readFile(path);
  const a = crypto.createHash('sha256').update(buf).digest('hex');
  const b = crypto.createHash('sha256').update(read).digest('hex');
  assert.strictEqual(a, b);
  assert.strictEqual(read.length, 1024);
  console.log('OK roundtrip.sha256=' + a);
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK roundtrip.sha256='
