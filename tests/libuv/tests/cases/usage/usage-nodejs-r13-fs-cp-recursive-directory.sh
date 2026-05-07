#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-fs-cp-recursive-directory
# @title: Node.js fs.cp with recursive copies a nested directory tree
# @description: Builds a two-level source directory with a file at each level, calls fs.promises.cp with recursive=true, and asserts both files are present at the destination with matching content.
# @timeout: 60
# @tags: usage, fs, promises, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/inner"
printf 'top-r13\n' >"$tmpdir/src/top.txt"
printf 'inner-r13\n' >"$tmpdir/src/inner/leaf.txt"

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  await fsp.cp('$tmpdir/src', '$tmpdir/dst', { recursive: true });
  const top = await fsp.readFile('$tmpdir/dst/top.txt', 'utf8');
  const leaf = await fsp.readFile('$tmpdir/dst/inner/leaf.txt', 'utf8');
  assert.strictEqual(top, 'top-r13\n');
  assert.strictEqual(leaf, 'inner-r13\n');
  console.log('OK fs.cp.recursive');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.cp.recursive'
