#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-fs-promises-stat-isdirectory
# @title: Node.js fs.promises.stat distinguishes file from directory
# @description: Calls fs.promises.stat against a regular file and its parent directory and asserts isFile and isDirectory return the expected booleans for each.
# @timeout: 60
# @tags: usage, fs, promises, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "payload" >"$tmpdir/file.txt"

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fs = require('fs/promises');
(async () => {
  const fileStat = await fs.stat('$tmpdir/file.txt');
  const dirStat = await fs.stat('$tmpdir');
  assert.strictEqual(fileStat.isFile(), true);
  assert.strictEqual(fileStat.isDirectory(), false);
  assert.strictEqual(dirStat.isFile(), false);
  assert.strictEqual(dirStat.isDirectory(), true);
  console.log('OK fs.promises.stat');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.stat'
