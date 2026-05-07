#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-fs-promises-copyfile-roundtrip
# @title: Node.js fs.promises.copyFile duplicates source bytes into destination
# @description: Writes a known payload to a source file, calls fs.promises.copyFile to a sibling destination, and asserts the destination contains identical bytes via fs.promises.readFile compared to the source.
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r15-copyfile-payload\n' >"$tmpdir/src.txt"

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const src = '$tmpdir/src.txt';
  const dst = '$tmpdir/dst.txt';
  await fsp.copyFile(src, dst);
  const a = await fsp.readFile(src);
  const b = await fsp.readFile(dst);
  assert.ok(a.equals(b), 'bytes mismatch');
  assert.strictEqual(b.toString('utf8'), 'r15-copyfile-payload\n');
  console.log('OK fs.promises.copyFile');
})().catch(e => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.copyFile'
