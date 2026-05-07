#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-fs-promises-lstat-symlink
# @title: Node.js fs.promises.lstat reports symlink status without following the link
# @description: Creates a regular file and a symbolic link pointing to it, awaits fs.promises.lstat on the link, and asserts isSymbolicLink is true and isFile is false; then awaits fs.promises.stat on the same link and asserts isFile is true (target is followed).
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'target\n' >"$tmpdir/target.txt"
ln -s "$tmpdir/target.txt" "$tmpdir/link"

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const dir = process.argv[2];
  const ls = await fsp.lstat(dir + '/link');
  assert.strictEqual(ls.isSymbolicLink(), true);
  assert.strictEqual(ls.isFile(), false);
  const st = await fsp.stat(dir + '/link');
  assert.strictEqual(st.isFile(), true);
  assert.strictEqual(st.isSymbolicLink(), false);
  console.log('OK fs.promises.lstat');
})().catch(e => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.lstat'
