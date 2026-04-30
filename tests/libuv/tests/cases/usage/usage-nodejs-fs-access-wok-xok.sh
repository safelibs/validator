#!/usr/bin/env bash
# @testcase: usage-nodejs-fs-access-wok-xok
# @title: Node.js fs.access W_OK and X_OK
# @description: Creates a writable plain file and an executable script then verifies fs.accessSync accepts W_OK on the file, X_OK on the script, and rejects X_OK on the plain non-executable file.
# @timeout: 120
# @tags: usage, nodejs, fs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/run.js" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const tmpdir = process.argv[2];
const writable = path.join(tmpdir, 'writable.txt');
const exe = path.join(tmpdir, 'runme.sh');

fs.writeFileSync(writable, 'data\n', { mode: 0o644 });
fs.writeFileSync(exe, '#!/bin/sh\necho ok\n', { mode: 0o755 });

fs.accessSync(writable, fs.constants.W_OK);
fs.accessSync(exe, fs.constants.X_OK);
fs.accessSync(exe, fs.constants.R_OK | fs.constants.X_OK);

let xokRejected = false;
try {
  fs.accessSync(writable, fs.constants.X_OK);
} catch (err) {
  assert.strictEqual(err.code, 'EACCES');
  xokRejected = true;
}
assert.ok(xokRejected, 'X_OK must reject on plain file');

console.log('OK access W_OK=ok X_OK-script=ok X_OK-plain=rejected');
JS

node "$tmpdir/run.js" "$tmpdir" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'OK access W_OK=ok X_OK-script=ok X_OK-plain=rejected'
