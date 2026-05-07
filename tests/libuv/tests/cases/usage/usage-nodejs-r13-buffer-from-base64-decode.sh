#!/usr/bin/env bash
# @testcase: usage-nodejs-r13-buffer-from-base64-decode
# @title: Node.js Buffer.from with base64 encoding decodes back to original bytes
# @description: Builds a base64 string from the literal text 'libuv-r13', decodes it via Buffer.from with the 'base64' encoding, and asserts the resulting buffer round-trips to the same UTF-8 string and length.
# @timeout: 60
# @tags: usage, buffer, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const original = 'libuv-r13';
const encoded = Buffer.from(original, 'utf8').toString('base64');
const decoded = Buffer.from(encoded, 'base64');
assert.ok(Buffer.isBuffer(decoded));
assert.strictEqual(decoded.length, original.length);
assert.strictEqual(decoded.toString('utf8'), original);
console.log('OK Buffer.base64');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK Buffer.base64'
