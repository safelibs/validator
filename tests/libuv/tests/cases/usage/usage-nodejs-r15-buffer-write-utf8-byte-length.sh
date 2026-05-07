#!/usr/bin/env bash
# @testcase: usage-nodejs-r15-buffer-write-utf8-byte-length
# @title: Node.js Buffer.byteLength reports two-byte length for the registered-trademark sign in UTF-8
# @description: Calls Buffer.byteLength on a string containing the registered-trademark sign and asserts the UTF-8 encoded length is 2 bytes (2-byte sequence) while the JavaScript string length stays at 1 character.
# @timeout: 60
# @tags: usage, buffer, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const sign = '®';
assert.strictEqual(sign.length, 1);
assert.strictEqual(Buffer.byteLength(sign, 'utf8'), 2);
const buf = Buffer.from(sign, 'utf8');
assert.strictEqual(buf.length, 2);
assert.strictEqual(buf.toString('utf8'), sign);
console.log('OK Buffer.byteLength.utf8');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK Buffer.byteLength.utf8'
