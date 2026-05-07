#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-fs-promises-rmdir-empty
# @title: Node.js fs.promises.rmdir removes an empty directory and reports ENOENT afterwards
# @description: Creates an empty directory, calls fs.promises.rmdir on it, then awaits fs.promises.stat and asserts the rejection has code 'ENOENT' confirming the directory no longer exists.
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/empty"

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fsp = require('fs/promises');
(async () => {
  const dir = '$tmpdir/empty';
  await fsp.rmdir(dir);
  let err;
  try {
    await fsp.stat(dir);
  } catch (e) {
    err = e;
  }
  assert.ok(err, 'expected stat to reject');
  assert.strictEqual(err.code, 'ENOENT');
  console.log('OK fs.promises.rmdir');
})().catch(e => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.promises.rmdir'
