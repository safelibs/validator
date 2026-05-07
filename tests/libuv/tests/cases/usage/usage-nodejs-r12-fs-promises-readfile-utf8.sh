#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-fs-promises-readfile-utf8
# @title: Node.js fs.promises.readFile decodes UTF-8 with explicit encoding
# @description: Writes a UTF-8 file containing non-ASCII characters and asserts fs.promises.readFile with encoding 'utf8' returns the original string.
# @timeout: 60
# @tags: usage, fs, promises, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'caf\xc3\xa9-r12\n' >"$tmpdir/in.txt"

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fs = require('fs/promises');
(async () => {
  const data = await fs.readFile('$tmpdir/in.txt', 'utf8');
  assert.strictEqual(typeof data, 'string');
  assert.strictEqual(data, 'café-r12\n');
  console.log('OK fs.promises.readFile');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.readFile'
