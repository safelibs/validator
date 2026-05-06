#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-events-on-async-iterator
# @title: Node.js events.on async iterator collects emitted payloads
# @description: Uses events.on to async-iterate a chain of typed events on an EventEmitter, breaking after a known count, and asserts the iterator yields the expected payload sequence.
# @timeout: 30
# @tags: usage, events, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

node - <<'JS'
const { EventEmitter, on } = require('events');
const assert = require('assert');

(async () => {
  const ee = new EventEmitter();
  setImmediate(() => {
    ee.emit('tick', 'a');
    ee.emit('tick', 'b');
    ee.emit('tick', 'c');
  });

  const collected = [];
  for await (const [v] of on(ee, 'tick')) {
    collected.push(v);
    if (collected.length === 3) break;
  }
  assert.deepStrictEqual(collected, ['a', 'b', 'c']);
})().catch(e => { console.error(e); process.exit(1); });
JS
