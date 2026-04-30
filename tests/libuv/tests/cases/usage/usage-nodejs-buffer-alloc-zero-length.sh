#!/usr/bin/env bash
# @testcase: usage-nodejs-buffer-alloc-zero-length
# @title: Node.js Buffer.alloc(0) zero-length semantics
# @description: Allocates a zero-length Buffer and verifies length 0, base64/hex encodings are empty, equality with Buffer.from(''), and Buffer.concat([]) yields the same shape.
# @timeout: 180
# @tags: usage, nodejs, buffer
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');

const buf = Buffer.alloc(0);
assert.strictEqual(buf.length, 0);
assert.strictEqual(Buffer.isBuffer(buf), true);
assert.strictEqual(buf.toString('utf8'), '');
assert.strictEqual(buf.toString('hex'), '');
assert.strictEqual(buf.toString('base64'), '');

const fromEmpty = Buffer.from('');
assert.strictEqual(fromEmpty.length, 0);
assert.ok(buf.equals(fromEmpty), 'alloc(0) must equal from("")');

const concat = Buffer.concat([]);
assert.strictEqual(concat.length, 0);
assert.ok(concat.equals(buf), 'concat([]) must equal alloc(0)');

const subarray = buf.subarray(0, 0);
assert.strictEqual(subarray.length, 0);

console.log('OK buffer-alloc-zero', buf.length, concat.length, fromEmpty.length);
JS

validator_assert_contains "$tmpdir/out" 'OK buffer-alloc-zero 0 0 0'
