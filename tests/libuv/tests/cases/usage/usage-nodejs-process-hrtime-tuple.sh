#!/usr/bin/env bash
# @testcase: usage-nodejs-process-hrtime-tuple
# @title: Node.js process.hrtime tuple monotonic with diff
# @description: Captures process.hrtime() once and again with the prior tuple as the diff base and asserts the elapsed seconds and nanoseconds are non-negative integers.
# @timeout: 120
# @tags: usage, process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');

const start = process.hrtime();
assert.ok(Array.isArray(start) && start.length === 2);
assert.strictEqual(typeof start[0], 'number');
assert.strictEqual(typeof start[1], 'number');
assert.ok(Number.isInteger(start[0]) && start[0] >= 0);
assert.ok(Number.isInteger(start[1]) && start[1] >= 0 && start[1] < 1e9);

let acc = 0;
for (let i = 0; i < 100000; i++) acc += i;
assert.ok(acc > 0);

const diff = process.hrtime(start);
assert.ok(Array.isArray(diff) && diff.length === 2);
assert.ok(diff[0] >= 0, 'seconds non-negative');
assert.ok(diff[1] >= 0 && diff[1] < 1e9, 'nanos within bounds');
const totalNs = diff[0] * 1e9 + diff[1];
assert.ok(totalNs >= 0, 'total nanoseconds non-negative');

console.log('OK hrtime-tuple monotonic');
JS

validator_assert_contains "$tmpdir/out" 'OK hrtime-tuple monotonic'
