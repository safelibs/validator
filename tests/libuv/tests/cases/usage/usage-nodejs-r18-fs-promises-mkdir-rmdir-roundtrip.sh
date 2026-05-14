#!/usr/bin/env bash
# @testcase: usage-nodejs-r18-fs-promises-mkdir-rmdir-roundtrip
# @title: Node.js fs.promises mkdir creates a directory that rmdir removes
# @description: Creates a temporary parent, calls fs.promises.mkdir on a nested target, asserts fs.promises.stat.isDirectory() returns true for the new path, then calls fs.promises.rmdir on the same path and asserts a subsequent fs.promises.access raises ENOENT, exercising libuv-backed directory create + remove primitives.
# @timeout: 60
# @tags: usage, nodejs, fs, mkdir, rmdir, r18
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
const { constants } = require('fs');
(async () => {
  const target = '$tmpdir/d1';
  await fsp.mkdir(target);
  const st = await fsp.stat(target);
  assert.strictEqual(st.isDirectory(), true);
  await fsp.rmdir(target);
  try {
    await fsp.access(target, constants.F_OK);
    throw new Error('directory still accessible after rmdir');
  } catch (e) {
    assert.strictEqual(e.code, 'ENOENT', 'unexpected code: ' + e.code);
  }
  console.log('OK mkdir.rmdir');
})().catch((e) => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK mkdir.rmdir'
