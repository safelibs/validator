#!/usr/bin/env bash
# @testcase: usage-nodejs-r21-fs-fdatasync-flushes-without-error
# @title: Node.js fs.fdatasync flushes a written file descriptor without error
# @description: Opens a temp file via fs.open in 'w+' mode, writes a payload via fs.writeSync, calls fs.fdatasync on the fd (libuv uv_fs_fdatasync request), asserts the callback fires with err === null, then closes and asserts the file contents match the payload.
# @timeout: 60
# @tags: usage, fs, fdatasync, nodejs, r21
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/s.js" <<JS
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const file = path.join(process.argv[2], 'data.bin');
const payload = Buffer.from('r21 fdatasync payload');

const fd = fs.openSync(file, 'w+');
fs.writeSync(fd, payload, 0, payload.length, 0);
fs.fdatasync(fd, (err) => {
  assert.strictEqual(err, null, 'fdatasync error: ' + err);
  fs.closeSync(fd);
  const got = fs.readFileSync(file);
  assert.deepStrictEqual(got, payload);
  console.log('OK fdatasync bytes=' + got.length);
});
JS

node "$tmpdir/s.js" "$tmpdir" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fdatasync'
