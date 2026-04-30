#!/usr/bin/env bash
# @testcase: usage-nodejs-timers-immediate-vs-timeout-order
# @title: Node.js timers setImmediate after I/O ordering
# @description: Schedules setImmediate inside an fs.readFile callback alongside setTimeout(0) and asserts setImmediate runs first.
# @timeout: 180
# @tags: usage, event-loop, timers
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

TARGET_FILE="$tmpdir/marker.txt" node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const fs = require('fs');

const file = process.env.TARGET_FILE;
fs.writeFileSync(file, 'hi');

const order = [];
fs.readFile(file, () => {
  setTimeout(() => order.push('timeout'), 0);
  setImmediate(() => order.push('immediate'));
  setTimeout(() => {
    assert.deepStrictEqual(order, ['immediate', 'timeout']);
    console.log('OK order', order.join(','));
  }, 50);
});
JS

validator_assert_contains "$tmpdir/out" 'OK order immediate,timeout'
