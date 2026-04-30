#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-promises-sha256-roundtrip
# @title: Node.js fs.promises write/read sha256 round trip
# @description: Writes random bytes via fs.promises.writeFile and verifies fs.promises.readFile returns identical content by sha256.
# @timeout: 180
# @tags: usage, fs, hash
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TARGET_FILE="$tmpdir/payload.bin" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const fsp = require('fs/promises');
const crypto = require('crypto');

(async () => {
  const file = process.env.TARGET_FILE;
  const payload = crypto.randomBytes(8192);
  const expected = crypto.createHash('sha256').update(payload).digest('hex');

  await fsp.writeFile(file, payload);
  const got = await fsp.readFile(file);
  assert.strictEqual(got.length, payload.length);
  const gotHash = crypto.createHash('sha256').update(got).digest('hex');
  assert.strictEqual(gotHash, expected);
  console.log('OK sha256', got.length, gotHash.slice(0, 12));
})().catch((e) => { console.error(e); process.exit(1); });
JS

validator_assert_contains "$tmpdir/out" 'OK sha256 8192'
