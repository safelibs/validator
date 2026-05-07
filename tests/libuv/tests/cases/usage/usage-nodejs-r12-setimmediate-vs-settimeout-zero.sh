#!/usr/bin/env bash
# @testcase: usage-nodejs-r12-setimmediate-vs-settimeout-zero
# @title: Node.js setImmediate fires after I/O when scheduled inside an fs callback
# @description: Schedules setTimeout(0) and setImmediate inside an fs.readFile callback and asserts setImmediate fires before setTimeout(0), per Node's documented I/O-then-immediate ordering.
# @timeout: 60
# @tags: usage, timers, event-loop, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "x" >"$tmpdir/probe.txt"

cat >"$tmpdir/script.js" <<JS
const assert = require('assert');
const fs = require('fs');
fs.readFile('$tmpdir/probe.txt', () => {
  const order = [];
  setTimeout(() => order.push('timeout'), 0);
  setImmediate(() => order.push('immediate'));
  setTimeout(() => {
    assert.strictEqual(order[0], 'immediate', 'order='+order.join(','));
    assert.strictEqual(order[1], 'timeout', 'order='+order.join(','));
    console.log('OK timers.order');
  }, 50);
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK timers.order'
