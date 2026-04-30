#!/usr/bin/env bash
# @testcase: usage-nodejs-events-once-removelistener
# @title: Node.js EventEmitter once and removeListener semantics
# @description: Verifies a once-listener fires exactly once, a removed listener does not fire, and listenerCount reaches zero after both unsubscribe.
# @timeout: 180
# @tags: usage, event-loop, events
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const assert = require('assert');
const { EventEmitter } = require('events');

const emitter = new EventEmitter();
let onceCalls = 0;
let regularCalls = 0;
const observed = [];

const onceListener = (value) => { onceCalls += 1; observed.push('once:' + value); };
const regularListener = (value) => { regularCalls += 1; observed.push('regular:' + value); };

emitter.once('ping', onceListener);
emitter.on('ping', regularListener);
assert.strictEqual(emitter.listenerCount('ping'), 2);

emitter.emit('ping', 'first');
emitter.emit('ping', 'second');

assert.strictEqual(onceCalls, 1);
assert.strictEqual(regularCalls, 2);
assert.strictEqual(emitter.listenerCount('ping'), 1);

emitter.removeListener('ping', regularListener);
assert.strictEqual(emitter.listenerCount('ping'), 0);

emitter.emit('ping', 'third');
assert.strictEqual(regularCalls, 2, 'regular must not fire after removeListener');
assert.deepStrictEqual(observed, ['once:first', 'regular:first', 'regular:second']);

setTimeout(() => {
  console.log('OK once-removelistener', onceCalls, regularCalls);
}, 50);
JS

validator_assert_contains "$tmpdir/out" 'OK once-removelistener 1 2'
