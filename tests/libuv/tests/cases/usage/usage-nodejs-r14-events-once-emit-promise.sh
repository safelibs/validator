#!/usr/bin/env bash
# @testcase: usage-nodejs-r14-events-once-emit-promise
# @title: Node.js events.once resolves with the emitted argument array
# @description: Constructs an EventEmitter, schedules emit('ready', 'a', 'b') on the next tick, and awaits events.once(emitter, 'ready') asserting the resolved value is the array ['a', 'b'].
# @timeout: 60
# @tags: usage, events, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/script.js" <<'JS'
const assert = require('assert');
const { EventEmitter, once } = require('events');
(async () => {
  const ee = new EventEmitter();
  process.nextTick(() => ee.emit('ready', 'a', 'b'));
  const args = await once(ee, 'ready');
  assert.deepStrictEqual(args, ['a', 'b']);
  console.log('OK events.once');
})().catch(e => { console.error(e); process.exit(1); });
JS

node "$tmpdir/script.js" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'OK events.once'
