#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-fs-appendfile-grows-file
# @title: Node.js fs.promises.appendFile appends data to an existing file
# @description: Writes an initial line to a file, calls fs.promises.appendFile with a second line, and asserts the resulting contents are the concatenation of both writes in order.
# @timeout: 60
# @tags: usage, fs, promises, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
const file = '$tmpdir/log.txt';
(async () => {
  await fsp.writeFile(file, 'first-r13\n');
  await fsp.appendFile(file, 'second-r13\n');
  const body = await fsp.readFile(file, 'utf8');
  assert.strictEqual(body, 'first-r13\nsecond-r13\n');
  console.log('OK fs.appendFile');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.appendFile'
