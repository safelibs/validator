#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-buffer-from-string-hex-encoding
# @title: Node.js Buffer.from('abc').toString('hex') yields the canonical '616263'
# @description: Constructs a Buffer from the ASCII string "abc", asserts toString('hex') returns the lowercase hex literal '616263', and asserts the Buffer length is 3 — exercising Node.js Buffer encoding on top of libuv runtime.
# @timeout: 60
# @tags: usage, nodejs, buffer, hex, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const buf = Buffer.from('abc');
assert.strictEqual(buf.length, 3);
assert.strictEqual(buf.toString('hex'), '616263');
console.log('OK hex.abc');
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK hex.abc'
