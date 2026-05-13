#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-util-promisify-fs-stat-returns-size
# @title: Node.js util.promisify(fs.stat) resolves to a Stats object whose size matches the file length
# @description: Writes a fixed-length payload to a temp file, calls util.promisify(fs.stat) on the path, asserts the result has numeric size equal to the payload byte length, asserts isFile() is true, and asserts an mtimeMs property is present as a number — exercising Node.js's libuv fs.stat surface through promisify.
# @timeout: 60
# @tags: usage, nodejs, fs, stat, promisify
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16-promisify-stat-1234' >"$tmpdir/payload.bin"
expected=$(wc -c <"$tmpdir/payload.bin")

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fs = require('fs');
const util = require('util');
const statp = util.promisify(fs.stat);
(async () => {
  const st = await statp('$tmpdir/payload.bin');
  assert.strictEqual(typeof st.size, 'number');
  assert.strictEqual(st.size, $expected);
  assert.strictEqual(typeof st.mtimeMs, 'number');
  assert.ok(st.isFile(), 'not a file');
  console.log('OK promisify.stat');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK promisify.stat'
