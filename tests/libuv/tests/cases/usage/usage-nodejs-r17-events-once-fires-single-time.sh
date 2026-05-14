#!/usr/bin/env bash
# @testcase: usage-nodejs-r17-events-once-fires-single-time
# @title: Node.js EventEmitter.once handler fires exactly once across multiple emits
# @description: Registers a once() handler on an EventEmitter, emits the event three times in a row, and asserts the handler counter increments to exactly 1 — confirming the libuv-backed Node.js event emitter unsubscribes the handler after the first invocation.
# @timeout: 60
# @tags: usage, nodejs, events, once, r17
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { EventEmitter } = require('events');
const ee = new EventEmitter();
let n = 0;
ee.once('ping', () => { n += 1; });
ee.emit('ping');
ee.emit('ping');
ee.emit('ping');
assert.strictEqual(n, 1);
console.log('OK once.n=' + n);
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK once.n=1'
