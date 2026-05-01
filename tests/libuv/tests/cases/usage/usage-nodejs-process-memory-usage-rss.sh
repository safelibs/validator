#!/usr/bin/env bash
# @testcase: usage-nodejs-process-memory-usage-rss
# @title: Node.js process.memoryUsage rss and heap fields positive
# @description: Calls process.memoryUsage() and asserts rss, heapTotal, heapUsed, and external are positive numbers with heapUsed <= heapTotal.
# @timeout: 120
# @tags: usage, process
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');

const m = process.memoryUsage();
assert.strictEqual(typeof m, 'object');
for (const key of ['rss', 'heapTotal', 'heapUsed', 'external', 'arrayBuffers']) {
  assert.strictEqual(typeof m[key], 'number', `${key} is number`);
  assert.ok(Number.isFinite(m[key]), `${key} finite`);
  assert.ok(m[key] >= 0, `${key} non-negative`);
}
assert.ok(m.rss > 0, 'rss positive');
assert.ok(m.heapTotal > 0, 'heapTotal positive');
assert.ok(m.heapUsed > 0, 'heapUsed positive');
assert.ok(m.heapUsed <= m.heapTotal, 'heapUsed <= heapTotal');

const rssOnly = process.memoryUsage.rss();
assert.strictEqual(typeof rssOnly, 'number');
assert.ok(rssOnly > 0, 'rss() positive');

console.log('OK memory-usage rss>0 heap-ordered');
JS

validator_assert_contains "$tmpdir/out" 'OK memory-usage rss>0 heap-ordered'
