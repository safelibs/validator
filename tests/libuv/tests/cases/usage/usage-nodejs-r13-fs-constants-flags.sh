#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-fs-constants-flags
# @title: Node.js fs.constants exposes POSIX access bits with conventional values
# @description: Reads fs.constants and asserts F_OK/R_OK/W_OK/X_OK are integers with the standard POSIX values 0/4/2/1, and that O_CREAT and O_RDONLY are exposed as numeric flags.
# @timeout: 60
# @tags: usage, fs, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const fs = require('fs');
const c = fs.constants;
assert.strictEqual(c.F_OK, 0);
assert.strictEqual(c.R_OK, 4);
assert.strictEqual(c.W_OK, 2);
assert.strictEqual(c.X_OK, 1);
assert.strictEqual(typeof c.O_CREAT, 'number');
assert.strictEqual(typeof c.O_RDONLY, 'number');
assert.ok(c.O_CREAT >= 0);
console.log('OK fs.constants');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK fs.constants'
