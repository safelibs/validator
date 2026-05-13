#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-crypto-randombytes-32-length
# @title: Node.js crypto.randomBytes(32) returns a 32-byte Buffer of non-zero entropy
# @description: Calls crypto.randomBytes(32) synchronously, asserts the returned value is a Buffer of length 32, and asserts at least one byte is non-zero — confirming Node.js's libuv-backed crypto random source emits the requested byte count.
# @timeout: 60
# @tags: usage, nodejs, crypto, random
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const crypto = require('crypto');
const buf = crypto.randomBytes(32);
assert.ok(Buffer.isBuffer(buf), 'not buffer');
assert.strictEqual(buf.length, 32);
const anyNonZero = buf.some((b) => b !== 0);
assert.ok(anyNonZero, 'all zero buffer');
console.log('OK randomBytes32');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK randomBytes32'
