#!/usr/bin/env bash
# @testcase: usage-nodejs-r16-setimmediate-fires-from-event-loop
# @title: Node.js setImmediate invokes its callback exactly once within the current event-loop turn
# @description: Schedules a setImmediate callback that increments a counter, returns from the synchronous script entry, and asserts via process.on('exit') that the callback ran exactly once before the loop drained — exercising Node.js's libuv check-phase scheduling.
# @timeout: 60
# @tags: usage, nodejs, timers, setimmediate
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
let counter = 0;
setImmediate(() => { counter += 1; });
process.on('exit', () => {
  assert.strictEqual(counter, 1, 'counter=' + counter);
  console.log('OK setImmediate');
});
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK setImmediate'
