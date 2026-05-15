#!/usr/bin/env bash
# @testcase: usage-nodejs-r20-buffer-compare-equal-and-unequal
# @title: Node.js Buffer.compare returns 0 for equal buffers and non-zero for differing ones
# @description: Builds two Buffers via Buffer.from('hello'), asserts Buffer.compare returns 0; then builds Buffer.from('hellp') and asserts Buffer.compare returns a non-zero integer in {-1, 1}, confirming Node's libuv-linked Buffer comparison helper returns sign-bounded results.
# @timeout: 60
# @tags: usage, nodejs, buffer, compare, r20
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const a = Buffer.from('hello');
const b = Buffer.from('hello');
const c = Buffer.from('hellp');
assert.strictEqual(Buffer.compare(a, b), 0);
const r = Buffer.compare(a, c);
assert.ok(r === -1 || r === 1, 'r=' + r);
console.log('OK compare eq=0 neq=' + r);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK compare eq=0'
