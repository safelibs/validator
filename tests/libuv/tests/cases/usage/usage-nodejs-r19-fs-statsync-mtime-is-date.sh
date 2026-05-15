#!/usr/bin/env bash
# @testcase: usage-nodejs-r19-fs-statsync-mtime-is-date
# @title: Node.js fs.statSync mtime is a Date instance with epoch greater than zero
# @description: Writes a temp file, calls fs.statSync on it, asserts the result.mtime is an instance of Date, asserts result.mtime.getTime() is a finite positive number, asserts result.atime and result.ctime are also Date instances, and asserts result.mtimeMs is a finite positive number, exercising libuv-backed stat field shape and types.
# @timeout: 60
# @tags: usage, nodejs, fs, stat, mtime, r19
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fs = require('fs');
const path = '$tmpdir/payload.bin';
fs.writeFileSync(path, 'hello\n');
const st = fs.statSync(path);
assert.ok(st.mtime instanceof Date, 'mtime not Date');
assert.ok(st.atime instanceof Date, 'atime not Date');
assert.ok(st.ctime instanceof Date, 'ctime not Date');
assert.ok(Number.isFinite(st.mtime.getTime()) && st.mtime.getTime() > 0, 'mtime epoch');
assert.ok(Number.isFinite(st.mtimeMs) && st.mtimeMs > 0, 'mtimeMs');
console.log('OK mtime.epoch=' + st.mtime.getTime());
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK mtime.epoch='
