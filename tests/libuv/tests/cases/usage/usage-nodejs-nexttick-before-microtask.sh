#!/usr/bin/env bash
# @testcase: usage-nodejs-nexttick-before-microtask
# @title: Node.js process.nextTick precedes queueMicrotask
# @description: Schedules process.nextTick and queueMicrotask in the same tick and asserts nextTick callbacks drain before the microtask queue.
# @timeout: 120
# @tags: usage, event-loop, timers
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const order = [];
queueMicrotask(() => order.push('microtask'));
process.nextTick(() => order.push('nextTick'));
setImmediate(() => {
  assert.deepStrictEqual(order, ['nextTick', 'microtask']);
  console.log('OK order ' + order.join(','));
});
JS

validator_assert_contains "$tmpdir/out" 'OK order nextTick,microtask'
